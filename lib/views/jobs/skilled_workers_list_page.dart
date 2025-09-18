import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/skilled_worker.dart';
import '../../services/job_service.dart';
import '../../widgets/app_scaffold_with_nav.dart'; 
import 'skilled_worker_detail_page.dart';

class SkilledWorkersListPage extends StatefulWidget {
  const SkilledWorkersListPage({super.key});

  @override
  State<SkilledWorkersListPage> createState() => _SkilledWorkersListPageState();
}

class _SkilledWorkersListPageState extends State<SkilledWorkersListPage> {
  late final JobService _jobService;
  late Future<List<SkilledWorker>> _workersFuture;

  @override
  void initState() {
    super.initState();
    _jobService = JobService(Supabase.instance.client);
    _workersFuture = _jobService.getSkilledWorkers();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(  
      title: 'Available Professionals',  
      currentRoute: '/jobs/skilled-workers', 
      body: FutureBuilder<List<SkilledWorker>>(
        future: _workersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final workers = snapshot.data;
          if (workers == null || workers.isEmpty) {
            return const Center(child: Text('No professionals available.'));
          }

          return ListView.builder(
            itemCount: workers.length,
            itemBuilder: (context, index) {
              final worker = workers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(worker.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(worker.primarySkill),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => SkilledWorkerDetailPage(worker: worker),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}