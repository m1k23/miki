import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() => runApp(MyApp());

class Tube {
  final String name;
  final String range;
  final List<Strand> strands;

  Tube({required this.name, required this.range, this.strands = const []});
}

class Strand {
  final int number;
  final Color color;
  final int blackMarks;

  Strand({required this.number, required this.color, this.blackMarks = 0});
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fiber Optic Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TubeListScreen(),
    );
  }
}

class TubeListScreen extends StatefulWidget {
  @override
  _TubeListScreenState createState() => _TubeListScreenState();
}

class _TubeListScreenState extends State<TubeListScreen> {
  List<Tube> tubes = [];
  Database? database;
  final List<Color> baseColors = [
    Colors.blue,    // 1
    Colors.orange,  // 2
    Colors.green,   // 3
    Colors.brown,   // 4
    Color(0xFF708090), // Gris
    Colors.white,   // 6
    Colors.red,     // 7
    Colors.black,   // 8
    Colors.yellow,  // 9
    Colors.purple,  // 10
    Color(0xFFFFC0CB), // Rosa
    Color(0xFF00CED1), // Cian
  ];

  @override
  void initState() {
    super.initState();
    _initDatabase();
    _generateSampleTubes();
  }

  Future<void> _initDatabase() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'tubes.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE tubes(name TEXT, range TEXT, strands TEXT)',
        );
      },
      version: 1,
    );
    _loadTubes();
  }

  void _generateSampleTubes() {
    for (int i = 0; i < 16; i++) {
      int start = i * 32 + 1;
      int end = (i + 1) * 32;
      List<Strand> strands = List.generate(32, (index) {
        int fiberNum = start + index;
        int colorIndex = (fiberNum - 1) % baseColors.length;
        int group = (fiberNum - 1) ~/ baseColors.length;
        int blackMarks = group > 0 ? group : 0;
        return Strand(
          number: fiberNum,
          color: baseColors[colorIndex],
          blackMarks: blackMarks,
        );
      });
      tubes.add(Tube(name: 'Tubo-${i + 1}', range: '$start-$end', strands: strands));
    }
    setState(() {});
  }

  Future<void> _loadTubes() async {
    // Placeholder
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fiber Optic Manager v1'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: tubes.length,
        itemBuilder: (context, index) {
          return ExpansionTile(
            title: Text('${tubes[index].name} (${tubes[index].range})'),
            children: tubes[index].strands.map((strand) {
              return ListTile(
                leading: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: strand.color,
                    border: strand.blackMarks > 0
                        ? Border.all(color: Colors.black, width: 2, style: BorderStyle.solid)
                        : null,
                  ),
                  child: strand.blackMarks > 0
                      ? CustomPaint(
                          painter: BlackMarkPainter(strand.blackMarks),
                        )
                      : null,
                ),
                title: Text('Fibra ${strand.number}'),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTubeDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  void _showSearchDialog() {
    String query = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Buscar Fibra'),
        content: TextField(
          onChanged: (value) => query = value,
          decoration: InputDecoration(labelText: 'Número de fibra'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () {
              int? fiberNum = int.tryParse(query);
              if (fiberNum != null) {
                int tubeIndex = ((fiberNum - 1) ~/ 32);
                if (tubeIndex < tubes.length) {
                  setState(() {
                    _expandTube(tubeIndex);
                  });
                }
              }
              Navigator.pop(context);
            },
            child: Text('Buscar'),
          ),
        ],
      ),
    );
  }

  void _expandTube(int index) {
    // Placeholder
  }

  void _showAddTubeDialog() {
    String name = '';
    String range = '';
    int fibersPerTube = 32;
    List<Strand> strands = [];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agregar Tubo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) => name = value,
              decoration: InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              onChanged: (value) => range = value,
              decoration: InputDecoration(labelText: 'Rango'),
            ),
            TextField(
              onChanged: (value) {
                int? newValue = int.tryParse(value);
                if (newValue != null) fibersPerTube = newValue;
              },
              decoration: InputDecoration(labelText: 'Fibras por tubo'),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: () {
                if (strands.length < fibersPerTube) {
                  setState(() {
                    int newFiberNum = strands.length + 1;
                    int colorIndex = (newFiberNum - 1) % baseColors.length;
                    int group = (newFiberNum - 1) ~/ baseColors.length;
                    strands.add(Strand(
                      number: newFiberNum,
                      color: baseColors[colorIndex],
                      blackMarks: group,
                    ));
                  });
                }
              },
              child: Text('Agregar Fibra'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (strands.isNotEmpty) {
                setState(() {
                  tubes.add(Tube(name: name, range: range, strands: strands));
                });
              }
              Navigator.pop(context);
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

// Painter personalizado para dibujar marcas negras
class BlackMarkPainter extends CustomPainter {
  final int marks;

  BlackMarkPainter(this.marks);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black..strokeWidth = 2;
    double step = size.width / (marks + 1);
    for (int i = 1; i <= marks; i++) {
      double x = i * step;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}