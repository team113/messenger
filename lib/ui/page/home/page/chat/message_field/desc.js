import core.widgets;

widget root = Container(
    height: 104.0,
    constraints: { minWidth: 300.0 },
    padding: [4.0, 4.0],
    decoration: {
    type: 'box',
    borderRadius: [{ x: 8.0, y: 8.0 }],
    gradient: {
        type: 'linear',
        begin: { x: 0.0, y: -1.0 },
        end: { x: 0.0, y: 1.0 },
        colors: [0xFFF9C924, 0xFFE4AF18, 0xFFFFF98C, 0xFFFFD440],
        stops: [0.0, 0.32, 0.68, 1.0],
    },
},
    child: Container(
        margin: [2.0, 2.0],
        decoration: {
        type: 'box',
        borderRadius: [{ x: 8.0, y: 8.0 }],
        gradient: {
            type: 'linear',
            begin: { x: -1.0, y: 0.0 },
            end: { x: 1.0, y: 0.0 },
            colors: [0xFFF9C924, 0xFFE4AF18, 0xFFFFF98C, 0xFFFFD440],
            stops: [0.0, 0.32, 0.68, 1.0],
        },
    },
        child: DefaultTextStyle(
            style: {
            color: 0xFFF3CD01,
            fontSize: 32.0,
            shadows: [
                {
                    offset: { x: 1.0, y: 1.0 },
                    blurRadius: 3.0,
                    color: 0xE4AC9200,
                },
                {
                    offset: { x: -1.0, y: -1.0 },
                    blurRadius: 2.0,
                    color: 0xE4FFFF00,
                },
                {
                    offset: { x: 1.0, y: -1.0 },
                    blurRadius: 2.0,
                    color: 0x33AC9200,
                },
                {
                    offset: { x: -1.0, y: 1.0 },
                    blurRadius: 2.0,
                    color: 0x33AC9200,
                },
            ],
        },
            child: Stack(
                children: [
                Align(
                    alignment: { x: -1.0, y: -1.0 },
                    child: Padding(
                        padding: [4.0, 4.0],
                        child: Text(
                            text: [data.name],
                            style: { fontSize: 17.0 },
                            textDirection: 'ltr',
                        ),
                    ),
                ),
                Align(
                    alignment: { x: 1.0, y: 1.0 },
                    child: Padding(
                        padding: [4.0, 4.0],
                        child: Text(
                            text: 'DONATION',
                            style: { fontSize: 13.0 },
                            textDirection: 'ltr',
                        ),
                    ),
                ),
                Center(
                    child: Text(
                        text: [data.description],
                        textDirection: 'ltr',

                    ),
                ),
            ],
            ),
        ),
    ),
);
