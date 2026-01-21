#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <errno.h>
#include <fcntl.h>
#include <math.h>
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <upower.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* utils_channel;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

struct TeeContext {
  int pipe_read_end;
  int original_fd;
  int log_file_fd;
};

static void* tee_thread(void* arg) {
  TeeContext* ctx = static_cast<TeeContext*>(arg);

  char buffer[4096];

  while (true) {
    ssize_t bytes_read =
        read(ctx->pipe_read_end, buffer, sizeof(buffer));

    if (bytes_read <= 0) {
      break;
    }

    // Write to log file
    write(ctx->log_file_fd, buffer, bytes_read);

    // Write back to original stream (stdout or stderr)
    write(ctx->original_fd, buffer, bytes_read);
  }

  return nullptr;
}

static void tee_fd_to_file(int target_fd, int log_file_fd) {
  int pipe_fds[2];
  pipe(pipe_fds);

  int pipe_read_end  = pipe_fds[0];
  int pipe_write_end = pipe_fds[1];

  // Preserve original stream FD
  int original_fd = dup(target_fd);

  // Redirect target FD into pipe
  dup2(pipe_write_end, target_fd);
  close(pipe_write_end);

  // Disable buffering so output appears immediately
  if (target_fd == STDOUT_FILENO) {
    setbuf(stdout, nullptr);
  } else if (target_fd == STDERR_FILENO) {
    setbuf(stderr, nullptr);
  }

  // Spawn background tee thread
  TeeContext* ctx = new TeeContext{
      .pipe_read_end = pipe_read_end,
      .original_fd   = original_fd,
      .log_file_fd   = log_file_fd,
  };

  pthread_t tid;
  pthread_create(&tid, nullptr, tee_thread, ctx);
  pthread_detach(tid);
}

static FlMethodResponse* redirect_std_out() {
  const char* log_path = "/tmp/app.log";

  // Open or create log file (append mode)
  int log_file_fd = open(
      log_path,
      O_CREAT | O_WRONLY | O_APPEND,
      0644);

  if (log_file_fd < 0) {
    char error_message[256];
    snprintf(error_message, sizeof(error_message),
             "Failed to open log file: %s", strerror(errno));

    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "FILE_ERROR", error_message, nullptr));
  }

  // Tee stdout and stderr
  tee_fd_to_file(STDOUT_FILENO, log_file_fd);
  tee_fd_to_file(STDERR_FILENO, log_file_fd);

  // Optional sanity message
  fprintf(stdout, "stdout/stderr redirected to %s\n", log_path);
  fprintf(stderr, "stderr also mirrored to %s\n", log_path);

  g_autoptr(FlValue) result =
      fl_value_new_string("ok");

  return FL_METHOD_RESPONSE(
      fl_method_success_response_new(result));
}

static void utils_method_call_handler(FlMethodChannel* channel,
                                        FlMethodCall* method_call,
                                        gpointer user_data) {
  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(fl_method_call_get_name(method_call), "redirectStdOut") == 0) {
    response = redirect_std_out();
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send response: %s", error->message);
  }
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "Gapopa");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "Gapopa");
  }

  gtk_window_set_default_size(window, 1280, 720);
  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(self->view));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->utils_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "team113.flutter.dev/linux_utils", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      self->utils_channel, utils_method_call_handler, self, nullptr);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_object(&self->utils_channel);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
