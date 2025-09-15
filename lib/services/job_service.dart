import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job_posting.dart';
import '../models/skilled_worker.dart';

class JobService {
  final SupabaseClient _client;

  JobService(this._client);

  // --- Job Postings Methods ---

  Future<List<JobPosting>> getJobPostings() async {
    final response = await _client.from('job_postings').select().eq('is_active', true).order('created_at', ascending: false);
    return (response as List).map((item) => JobPosting.fromMap(item)).toList();
  }

  // NEW: Get job postings for a specific owner
  Future<List<JobPosting>> getJobPostingsForOwner(String ownerId) async {
    final response = await _client.from('job_postings').select().eq('owner_id', ownerId).order('created_at', ascending: false);
    return (response as List).map((item) => JobPosting.fromMap(item)).toList();
  }

  Future<void> createJobPosting(JobPosting posting) async {
    await _client.from('job_postings').insert(posting.toMap());
  }
  
  Future<void> updateJobPosting(JobPosting posting) async {
    await _client.from('job_postings').update(posting.toMap()).eq('id', posting.id);
  }

  Future<void> deleteJobPosting(String id) async {
    await _client.from('job_postings').delete().eq('id', id);
  }

  Future<void> toggleJobPostingStatus(String postId, bool currentStatus) async {
    await _client
        .from('job_postings')
        .update({'is_active': !currentStatus})
        .eq('id', postId);
  }

  // --- Skilled Workers Methods ---

  Future<List<SkilledWorker>> getSkilledWorkers() async {
    final response = await _client.from('skilled_workers').select().eq('is_available', true).order('created_at', ascending: false);
    return (response as List).map((item) => SkilledWorker.fromMap(item)).toList();
  }

  // NEW: Get a skilled worker profile for a specific owner
  Future<SkilledWorker?> getSkilledWorkerForOwner(String ownerId) async {
    final response = await _client.from('skilled_workers').select().eq('owner_id', ownerId).maybeSingle();
    if (response == null) {
      return null;
    }
    return SkilledWorker.fromMap(response);
  }
  
  Future<void> createSkilledWorker(SkilledWorker worker) async {
    await _client.from('skilled_workers').insert(worker.toMap());
  }

  Future<void> updateSkilledWorker(SkilledWorker worker) async {
    await _client.from('skilled_workers').update(worker.toMap()).eq('id', worker.id);
  }

  Future<void> deleteSkilledWorker(String id) async {
    await _client.from('skilled_workers').delete().eq('id', id);
  }
}