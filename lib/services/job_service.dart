import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job_posting.dart';
import '../models/skilled_worker.dart';

class JobService {
  final SupabaseClient _client;
  JobService(this._client);

  // --- Job Postings Methods ---
  Future<List<JobPosting>> getJobPostings() async {
    final response = await _client
        .from('job_postings')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return (response as List)
        .map((item) => JobPosting.fromMap(item))
        .toList();
  }

  Future<JobPosting?> getJobPostingById(String id) async {
    final response = await _client
        .from('job_postings')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response == null ? null : JobPosting.fromMap(response);
  }

  Future<List<JobPosting>> getJobPostingsForOwner(String ownerId) async {
    final response = await _client
        .from('job_postings')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((item) => JobPosting.fromMap(item))
        .toList();
  }

  Future<void> createJobPosting(JobPosting posting) async {
    await _client.from('job_postings').insert(posting.toMap());
  }

  Future<void> updateJobPosting(JobPosting posting) async {
    await _client
        .from('job_postings')
        .update(posting.toMap())
        .eq('id', posting.id);
  }

  Future<void> toggleJobPostingStatus(String postId, bool currentStatus) async {
    await _client
        .from('job_postings')
        .update({'is_active': !currentStatus})
        .eq('id', postId);
  }

  Future<List<JobPosting>> getMyJobPostings(String userId) async {
    final response = await _client
        .from('job_postings')
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((item) => JobPosting.fromMap(item))
        .toList();
  }

  // --- Skilled Workers Methods ---
  Future<List<SkilledWorker>> getSkilledWorkers() async {
    final response = await _client
        .from('skilled_workers')
        .select()
        .eq('is_available', true)
        .order('created_at', ascending: false);
    return (response as List)
        .map((item) => SkilledWorker.fromMap(item))
        .toList();
  }

  Future<SkilledWorker?> getSkilledWorkerById(String id) async {
    final response = await _client
        .from('skilled_workers')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response == null ? null : SkilledWorker.fromMap(response);
  }

  Future<SkilledWorker?> getSkilledWorkerForOwner(String ownerId) async {
    final response = await _client
        .from('skilled_workers')
        .select()
        .eq('owner_id', ownerId)
        .maybeSingle();
    return response == null ? null : SkilledWorker.fromMap(response);
  }

  Future<void> createSkilledWorker(SkilledWorker worker) async {
    await _client.from('skilled_workers').insert(worker.toMap());
  }

  Future<void> updateSkilledWorker(SkilledWorker worker) async {
    await _client
        .from('skilled_workers')
        .update(worker.toMap())
        .eq('id', worker.id);
  }

  Future<List<SkilledWorker>> getMySkilledWorkers(String userId) async {
    final response = await _client
        .from('skilled_workers')
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((item) => SkilledWorker.fromMap(item))
        .toList();
  }
}