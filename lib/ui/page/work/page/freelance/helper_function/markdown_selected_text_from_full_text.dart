//Purpose of the Function
//This function reconstructs the original selected text with
// correct line breaks (\n) from the full markdown text.
//It solves a Flutter selection limitation


String markdownSelectedTextFromFullText({
  required String fullText,
  required String selectedText,
}) {
  fullText = fullText.replaceAll(RegExp(r'[#\[\]`]|[^\x20-\x7E\n\r]'), '');
  fullText = fullText.replaceAll(' - ', ' • ');
  selectedText = selectedText.replaceAll(RegExp(r'[#]|[^\x20-\x7E\n\r]'), '');
  String result = '';
  if (selectedText.isEmpty) {
    return '';
  }
  if (fullText.contains(selectedText)) {
    return selectedText;
  }

  ///Search for beginning
  ///iterate selectedText from the start when full text don't contain beginning string
  ///beginning-last character is beginning String
  String beginning = '';
  for (int i = 0; i < selectedText.length; i++) {
    beginning = beginning + selectedText[i];
    if (!fullText.contains(beginning)) {
      beginning = beginning.substring(0, beginning.length - 1);
      break;
    }
  }

  ///Search for end
  ///iterate selectedText from the end and when full text don't contain end String
  /// end-first character is the end

  String end = '';
  for (int i = selectedText.length - 1; i >= 0; i--) {
    end = selectedText[i] + end;
    if (!fullText.contains(end)) {
      end = end.substring(1, end.length);
      break;
    }
  }

  ///Remove all before beginning
  ///Split with beginning String and remove the last.

  List<String> beginningList = fullText.split(beginning);
  beginningList.removeAt(0);
  result = beginning + beginningList.join(beginning);

  ///Remove all after end
  ///Split with end string and remove last
  ///Join first from the start nd last from the end.
  List<String> endList = result.split(end);
  if(endList.length>2){
    String selectedTextWithoutEnd= selectedText.substring(0,selectedText.length-end.length);

    String newEnd='';
    for (int i = selectedTextWithoutEnd.length - 1; i >= 0; i--) {
      newEnd = selectedTextWithoutEnd[i] + newEnd;
      if (!fullText.contains(newEnd)) {
        newEnd = newEnd.substring(1, newEnd.length);
        break;
      }
    }

    List<String> endList = result.split(newEnd);
    endList.removeLast();
    result = endList.join(newEnd) + newEnd;
  }else{
    endList.removeLast();
    result = endList.join(end) + end;}

  return result;
}


