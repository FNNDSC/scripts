Database = function() {
  
  this._cases = {};
  
};

Database.prototype.jumpToLine = function(content,dataAsArray) {
  
  for (var i=0; i<dataAsArray.length; i++) {
    
    if (jQuery.trim(dataAsArray[i]) == content) {
      
      return i;
      
    }
    
  }
  
  // couldn't find it
  return -1;
  
};

Database.prototype.parseAndAddFile = function(fileName, data) {
  
  debug('Parsing '+fileName)

  var dataAsArray = data.split('\n');
  var index = 0;
  
  // check for a valid header
  if (jQuery.trim(dataAsArray[index]) != 'QMass MR RESULTS REPORT') {
    
    error('Unrecognized file!');
    return;
    
  }
  
  
  // get the case id and type by splitting the filename
  fileName = fileName.toUpperCase();
  var splittedFileName1 = fileName.split('PRECONTRAST');
  var splittedFileName2 = fileName.split('POSTCONTRAST');
  
  if (splittedFileName1.length == 1 && splittedFileName2.length == 1) {
    
    error('Could not parse file: ' + fileName);
    return;
    
  }
  
  // check for pre or postcontrast
  var caseName = "";
  var caseType = "";
  var caseNumber = "";  
  
  if(splittedFileName1.length > 1) {
    
    caseName = splittedFileName1[0];
    caseType = 'precontrast';
    caseNumber = 1;
    
  } else if (splittedFileName2.length > 1) {
    
    caseName = splittedFileName2[0];
    caseType = 'postcontrast';
    caseNumber = splittedFileName2[1].substr(0,splittedFileName2[1].indexOf('.'));
    
  }
    
  debug('Found ' + caseName + ' - ' + caseType + ' ' + caseNumber);
  
  // check if we already have this patient
  var caze = null;
  var patient = null;
  
  if (!(caseName in this._cases)) {
    
    // create a new case
    caze = new Case();
    caze._name = caseName;
    
    // create a new patient
    patient = new Patient();
    index = 10;
    patient._name = jQuery.trim(dataAsArray[index++].split(':')[1]);
    patient._id = jQuery.trim(dataAsArray[index++].split(':')[1]);
    patient._gender = jQuery.trim(dataAsArray[index++].split(':')[1]);
    patient._birthday = jQuery.trim(dataAsArray[index++].split(':')[1]);
    patient._weight = jQuery.trim(dataAsArray[index++].split(':')[1]);
    patient._height = jQuery.trim(dataAsArray[index++].split(':')[1]);
    
    caze._patient = patient;
    
    // push it
    this._cases[caseName] = caze;

  } else {
    
    // grab the existing case
    caze = this._cases[caseName];
    
  }
  
  // parse the data
  var dataset = new Dataset();
  
  var volumesStartLine = this.jumpToLine('VOLUMES [ml]', dataAsArray);
  
  if (volumesStartLine == -1) {
    
    error('Could not parse file: ' + fileName);
    return;
    
  }
  
  var l = 0;
  var line = dataAsArray[volumesStartLine+5+l];
  
  while (jQuery.trim(line) != "") {
    
    dataset.parseAndAddVolumes(line);
    line = dataAsArray[volumesStartLine+5+(l++)];
    
  }
  
  var signalIntensitiesStartLine = this.jumpToLine('Absolute signal intensities [au]:', dataAsArray);
  
  if (signalIntensitiesStartLine == -1) {
    
    error('Could not parse file: ' + fileName);
    return;
    
  }
  
  l=0;
  line = dataAsArray[signalIntensitiesStartLine+4+l];
  
  while (jQuery.trim(line) != "") {
    
    dataset.parseAndAddSignalIntensities(line);
    line = dataAsArray[signalIntensitiesStartLine+4+(l++)];
    
  }
  
  if (caseType == "postcontrast") {
    
    caze._postcontrast[caseNumber] = dataset; 
      
  } else if (caseType == "precontrast") {
    
    caze._precontrast[caseNumber] = dataset;
    
  }

  debug('Completed.');
};