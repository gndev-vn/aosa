import 'dart:async';
import '../entities/otp_account.dart';

abstract class OtpRepository {
  Future<List<OtpAccount>> getAll();
  Stream<List<OtpAccount>> watchAll();
  Future<OtpAccount?> getById(String id);
  Future<void> save(OtpAccount account);
  Future<void> delete(String id);
  Future<int> count();
  Future<List<OtpAccount>> search(String query);
}
