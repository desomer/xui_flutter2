import 'package:flutter/material.dart';

class ExpandInfo {
  ExpandInfo(this.body, this.title, [this.isExpanded = false]);
  bool isExpanded;
  Widget body;
  Widget title;
}

class ExpandPanel extends StatefulWidget {
  final List<ExpandInfo> steps;
  const ExpandPanel({Key? key, required this.steps}) : super(key: key);
  @override
  State<ExpandPanel> createState() => ExpandPanelState();
}

class ExpandPanelState extends State<ExpandPanel> {
  @override
  Widget build(BuildContext context) {
    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          widget.steps[index].isExpanded = !isExpanded;
        });
      },
      children: widget.steps.map<ExpansionPanel>((ExpandInfo step) {
        return ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              dense: true,
              title: step.title,
            );
          },
          body: ListTile(
            dense: true,
            title: step.body,
          ),
          isExpanded: step.isExpanded,
        );
      }).toList(),
    );
  }
}

/////////////////////////////////////////////////////////////////////
class Step {
  Step(this.title, this.body, [this.isExpanded = false]);
  String title;
  String body;
  bool isExpanded;
}

Future<List<Step>> getSteps() async {
  var items = [
    Step('Step 0: Install Flutter',
        'Install Flutter development tools according to the official documentation.'),
    Step('Step 1: Create a project',
        'Open your terminal, run `flutter create <project_name>` to create a new project.'),
    Step('Step 2: Run the app',
        'Change your terminal directory to the project directory, enter `flutter run`.'),
  ];
  return Future<List<Step>>.delayed(const Duration(seconds: 2), () => items);
}

class Steps extends StatelessWidget {
  const Steps({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: FutureBuilder<List<Step>>(
          future: getSteps(),
          builder:
              (BuildContext context, AsyncSnapshot<List<Step>> snapshot) {
            if (snapshot.hasData) {
              return StepList(steps: snapshot.data ?? []);
            } else {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
          }),
    );
  }
}

class StepList extends StatefulWidget {
  final List<Step> steps;
  const StepList({Key? key, required this.steps}) : super(key: key);
  @override
  // ignore: no_logic_in_create_state
  State<StepList> createState() => _StepListState(steps: steps);
}

class _StepListState extends State<StepList> {
  final List<Step> _steps;
  _StepListState({required List<Step> steps}) : _steps = steps;
  @override
  Widget build(BuildContext context) {
    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          _steps[index].isExpanded = !isExpanded;
        });
      },
      children: _steps.map<ExpansionPanel>((Step step) {
        return ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return PreferredSize(
                preferredSize: const Size.fromHeight(20),
                child: ListTile(
                  tileColor: Colors.indigo,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  dense: true,
                  title: Text(step.title),
                ));
          },
          body: ListTile(
            title: Text(step.body),
          ),
          isExpanded: step.isExpanded,
        );
      }).toList(),
    );
  }
}


