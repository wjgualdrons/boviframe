import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:boviframe/services/local_firestore.dart';
import '../../widgets/custom_app_scaffold.dart';

class NewSessionScreen extends StatefulWidget {
  final String? sessionId;
  final dynamic numeroSesion;

  const NewSessionScreen({Key? key, this.sessionId, this.numeroSesion})
    : super(key: key);
  @override
  State<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends State<NewSessionScreen> {
  late Future<int> _futureNumeroSesion;

  @override
  void initState() {
    super.initState();
    _futureNumeroSesion = _generarNumeroSesion();
  }

  Future<int> _generarNumeroSesion() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final snapshot =
        await LocalFirestore.instance
            .collection('sesiones')
            .where('userId', isEqualTo: userId)
            .get();
    return snapshot.docs.length + 1;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _futureNumeroSesion,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final numeroSesion = snapshot.data!;
        return CustomAppScaffold(
          currentIndex: 2,
          title: 'Nueva SesiÃ³n',
          showBackButton: true,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
            child: Column(
              children: [
                _buildSectionButton(
                  context,
                  label: 'Datos del Productor',
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        '/datos_productor',
                        arguments: {
                          'sessionId': widget.sessionId,
                          'numeroSesion': numeroSesion,
                        },
                      ),
                  highlighted: true,
                ),
                const SizedBox(height: 16),
                _buildSectionButton(
                  context,
                  label: 'EvaluaciÃ³n del Animal',
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        '/animal_evaluation',
                        arguments: {
                          'sessionId': widget.sessionId,
                          'numeroSesion': numeroSesion,
                        },
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    final Color bgColor = Colors.blue[50]!;
    final Color textColor = Colors.blue[800]!;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}



