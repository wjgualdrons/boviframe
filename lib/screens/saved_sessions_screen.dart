import 'package:boviframe/services/local_firestore.dart';
import 'package:flutter/material.dart';

class SavedSessionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firestore = LocalFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: Text('Sesiones Guardadas')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            firestore
                .collection('unidades')
                .orderBy('fechaGuardado', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No hay sesiones guardadas'));
          }

          final sesiones = snapshot.data!.docs;

          return ListView.builder(
            itemCount: sesiones.length,
            itemBuilder: (context, index) {
              final data = sesiones[index].data() as Map<String, dynamic>;
              final fecha = (data['fechaGuardado'] as Timestamp).toDate();

              return ListTile(
                title: Text(data['nombre'] ?? 'Sin nombre'),
                subtitle: Text(
                  'Guardado el: ${fecha.toLocal().toString().split(" ")[0]}',
                ),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  // AquÃ­ puedes navegar a una pantalla con los detalles
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => SessionDetailView(data: data)));
                },
              );
            },
          );
        },
      ),
    );
  }
}



