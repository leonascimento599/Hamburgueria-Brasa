import 'package:dart_frog/dart_frog.dart';
import '../lib/menu_data.dart';

Response onRequest(RequestContext context) {
  return Response.json(body: menuResponse);
}
