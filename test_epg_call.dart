import 'package:openiptv/src/data/stalker_api_service.dart';
import 'package:openiptv/src/data/models.dart'; // Assuming Channel is defined here

void testEpgCall() async {
  final StalkerApiService apiService = StalkerApiService("http://example.com"); // Dummy base URL
  final Channel channel = Channel(id: "test_channel_id", name: "Test Channel", logoUrl: "", streamUrl: ""); // Dummy Channel
  
  // The problematic call
  final epgPrograms = await apiService.getEpgInfo(chId: channel.id, period: 24);
  print("EPG Programs: $epgPrograms");
}