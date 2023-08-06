import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// postgre _r$y-74WSMFKk8

class SupabaseDriver {
  Future<void> supabase() async {
    await Supabase.initialize(
      url: "https://pkrutsmghgjxapkozcyn.supabase.co",
      anonKey:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBrcnV0c21naGdqeGFwa296Y3luIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTEyNzI4MjgsImV4cCI6MjAwNjg0ODgyOH0.nlADIUSTgwWCZ9Q2vUgr6iwPHBZwxSjLlQKCV_zdt8I",
    );

    // It's handy to then extract the Supabase client in a variable for later uses
    final supabase = Supabase.instance.client;

    AuthResponse res = await supabase.auth.signInWithPassword(
      email: "gauthier.desomer@gmail.com",
      password: "Charley.30",
    );

    // ignore: unused_local_variable
    final Session? session = res.session;
    // ignore: unused_local_variable
    final User? user = res.user;

    // Listen to auth state changes
    // supabase.auth.onAuthStateChange.listen((data) {
    //   final AuthChangeEvent event = data.event;
    //   final Session? session = data.session;
    //   // Do something when there is an auth event
    // });

    // await supabase.from('ListModel').insert({
    //   "json": {"ok": "good"}
    // });
    final data = await supabase.from('ListModel').select('json');
    debugPrint(data.toString());
  }
}
