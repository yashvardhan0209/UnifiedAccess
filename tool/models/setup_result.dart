class SetupResult {
  final List<String> changesMade = [];
  final List<String> manualSteps = [];
  final List<String> backupFiles = [];
  final List<String> warnings = [];

  void addChange(String description) => changesMade.add(description);
  void addManualStep(String description) => manualSteps.add(description);
  void addBackup(String filePath) => backupFiles.add(filePath);
  void addWarning(String description) => warnings.add(description);
}
