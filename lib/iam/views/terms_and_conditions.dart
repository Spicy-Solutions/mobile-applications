import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: Column(
        children: [
          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Términos y Condiciones de Uso',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Al acceder, descargar o utilizar la aplicación móvil Sweet Manager (en adelante, "la Aplicación"), usted declara que ha leído, comprendido y aceptado los términos y condiciones establecidos en este documento. La utilización de la Aplicación constituye un acuerdo vinculante entre el usuario y SweetSolutions (en adelante, "la Empresa"), propietaria y operadora de la Aplicación. Si no está de acuerdo con alguna de las disposiciones aquí contenidas, se solicita que se abstenga de utilizar la Aplicación.',
                      textAlign: TextAlign.justify,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'La Aplicación está diseñada para facilitar la gestión integral de hoteles, permitiendo a los administradores y trabajadores realizar tareas como el registro de clientes, gestión de habitaciones, reportes de incidencias, manejo de notificaciones, administración de suministros y proveedores, entre otras funcionalidades destinadas a optimizar las operaciones cotidianas de un hotel.',
                      textAlign: TextAlign.justify,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'El registro en la Aplicación requiere el suministro de información personal, como nombre completo, correo electrónico válido y número de teléfono celular. Al registrarse, el usuario acepta que esta información será utilizada exclusivamente para fines relacionados con la prestación del servicio y se compromete a mantener la confidencialidad de sus credenciales de acceso.',
                      textAlign: TextAlign.justify,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'La protección de los datos personales de los usuarios es una prioridad para SweetSolutions. Los datos recopilados serán tratados de manera confidencial y estarán protegidos mediante medidas de seguridad como la implementación de tokens en el backend para evitar accesos no autorizados.',
                      textAlign: TextAlign.justify,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'El uso completo de la Aplicación está condicionado a la adquisición de planes de suscripción, cuyo pago se realizará exclusivamente mediante tarjeta de crédito o débito. Los precios, características y duraciones de los planes estarán claramente especificados dentro de la Aplicación.',
                      textAlign: TextAlign.justify,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Todos los derechos de propiedad intelectual relacionados con la Aplicación, incluyendo su diseño, funcionalidades y contenido, son de exclusiva propiedad de SweetSolutions.',
                      textAlign: TextAlign.justify,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Estos términos y condiciones, así como cualquier disputa relacionada con la Aplicación, se regirán por las leyes de la República del Perú. En caso de controversias, las partes acuerdan someterse a la jurisdicción exclusiva de los tribunales peruanos.',
                      textAlign: TextAlign.justify,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Para cualquier consulta, queja o solicitud relacionada con estos términos y condiciones, los usuarios pueden contactarnos mediante el correo electrónico sweetsolutions@gmail.com.',
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Aceptar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Rechazar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}