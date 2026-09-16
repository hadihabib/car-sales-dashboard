import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient client;

  DatabaseService({
    required String url,
    required String publishableKey,
  }) : client = SupabaseClient(url, publishableKey);

  Future<void> testConnection() async {
    await client.from('transactions').select('id').limit(1);
  }

  Future<List<Map<String, dynamic>>> getTransactions({
    int limit = 500,
  }) async {
    final data = await client
        .from('transactions')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addTransaction(Map<String, dynamic> values) async {
    await client.from('transactions').insert(values);
  }

  Future<void> updateTransaction(
    int id,
    Map<String, dynamic> values,
  ) async {
    values['updated_at'] = DateTime.now().toUtc().toIso8601String();
    await client.from('transactions').update(values).eq('id', id);
  }

  Future<void> deleteTransaction(int id) async {
    await client.from('transactions').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getMerchants() async {
    final data = await client.from('merchants').select().order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addMerchant(Map<String, dynamic> values) async {
    await client.from('merchants').insert(values);
  }

  Future<void> updateMerchant(
    int id,
    Map<String, dynamic> values,
  ) async {
    values['updated_at'] = DateTime.now().toUtc().toIso8601String();
    await client.from('merchants').update(values).eq('id', id);
  }

  Future<void> deleteMerchant(int id) async {
    await client.from('merchants').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getLedger({
    int? merchantId,
  }) async {
    var query = client.from('merchant_ledger').select();
    if (merchantId != null) {
      query = query.eq('merchant_id', merchantId);
    }

    final data = await query
        .order('movement_date', ascending: false)
        .order('id', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addLedger(Map<String, dynamic> values) async {
    await client.from('merchant_ledger').insert(values);
  }

  Future<void> updateLedger(
    int id,
    Map<String, dynamic> values,
  ) async {
    values['updated_at'] = DateTime.now().toUtc().toIso8601String();
    await client.from('merchant_ledger').update(values).eq('id', id);
  }

  Future<void> deleteLedger(int id) async {
    await client.from('merchant_ledger').delete().eq('id', id);
  }
}
