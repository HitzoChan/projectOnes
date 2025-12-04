import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/firestore_provider.dart';

class BackfillAttendanceScreen extends StatefulWidget {
  const BackfillAttendanceScreen({super.key});

  @override
  State<BackfillAttendanceScreen> createState() => _BackfillAttendanceScreenState();
}

class _BackfillAttendanceScreenState extends State<BackfillAttendanceScreen> {
  bool _running = false;
  String _status = '';

  Future<void> _runBackfill() async {
    if (_running) return;
    setState(() {
      _running = true;
      _status = 'Starting backfill...';
    });

    final provider = Provider.of<FirestoreProvider>(context, listen: false);
    try {
      final updated = await provider.backfillAttendanceTeacherIds(batchSize: 200);
      if (mounted) {
        setState(() {
          _status = 'Backfill complete. Updated $updated documents.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backfill complete. Updated $updated documents.')),
        );
      }
    } catch (e, st) {
      debugPrint('Backfill failed: $e\n$st');
      if (mounted) {
        setState(() {
          _status = 'Backfill failed: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backfill failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
        });
      }
    }
  }

  Future<void> _runDedupe() async {
    if (_running) return;
    setState(() {
      _running = true;
      _status = 'Starting dedupe...';
    });

    final provider = Provider.of<FirestoreProvider>(context, listen: false);
    try {
      final deleted = await provider.dedupeAttendanceDocs(batchSize: 200);
      if (mounted) {
        setState(() {
          _status = 'Dedupe complete. Deleted $deleted duplicate documents.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dedupe complete. Deleted $deleted documents.')),
        );
      }
    } catch (e, st) {
      debugPrint('Dedupe failed: $e\n$st');
      if (mounted) {
        setState(() {
          _status = 'Dedupe failed: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dedupe failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Protect this screen: only in debug mode
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Backfill')),
        body: const Center(child: Text('Admin tools are available in debug builds only.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Backfill Attendance Teacher IDs')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This operation will add `teacherId` to attendance documents that are missing it.\n\nUse a small batch size first to verify behavior.',
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _running ? null : _runBackfill,
              icon: _running ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.build),
              label: Text(_running ? 'Running...' : 'Run Backfill (batchSize=200)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _running ? null : _runDedupe,
              icon: _running ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cleaning_services),
              label: Text(_running ? 'Running...' : 'Run Dedupe (batchSize=200)'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
            ),
            const SizedBox(height: 12),
            Text('Status: $_status'),
            const SizedBox(height: 8),
            const Text('Recommended: run on dev/staging or small batch first (batchSize: 50).'),
          ],
        ),
      ),
    );
  }
}
