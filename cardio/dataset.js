Dataset = function() {
  
  this._data = [];
  
  this._lvBloodT1 = 0;
  this._s1T1 = 0;
  this._s2T1 = 0;
  this._s3T1 = 0;
  this._s4T1 = 0;
  this._s5T1 = 0;
  this._s6T1 = 0;
  this._meanT1 = 0;    
  
  
}

Dataset.toFloat = function(string) {
  
  // remove comma and cast to float
  return parseFloat(string.replace(/,/g,''));
  
}

Dataset.prototype.parseAndAddVolumes = function(line) {
  
  var lineAsArray = line.split(' ').filter(function(a){if (a!="") return true;})
  
  var data = new Data();
  data._time = Dataset.toFloat(lineAsArray[1]);
  data._lvEndo = Dataset.toFloat(lineAsArray[2]);
  data._lvEpi = Dataset.toFloat(lineAsArray[3]);
  data._bloodpool = Dataset.toFloat(lineAsArray[4]);
  data._myo = Dataset.toFloat(lineAsArray[5]);
  data._roi1 = Dataset.toFloat(lineAsArray[6]);
  data._roi2 = Dataset.toFloat(lineAsArray[7]);
  data._roi3 = Dataset.toFloat(lineAsArray[8]);
  data._roi4 = Dataset.toFloat(lineAsArray[9]);
  
  this._data[lineAsArray[0]] = data;
  
}

Dataset.prototype.parseAndAddSignalIntensities = function(line) {
  
  var lineAsArray = jQuery.trim(line).split(' ').filter(function(a){if (a!="") return true;})
  
  var fieldName = '';
  if (lineAsArray[0] == 'LV') {
    
    // 2 because we ignore the BLOOD
    for (var k=2;k<lineAsArray.length;k++) {

      this._data[k-1]._lvBlood = Dataset.toFloat(lineAsArray[k]);
      
    }
    
  } else if (lineAsArray[0] == 'S1') {
    
    for (var k=1;k<lineAsArray.length;k++) {
      
      this._data[k]._s1 = Dataset.toFloat(lineAsArray[k]);
      
    }
    
  } else if (lineAsArray[0] == 'S2') {
    
    for (var k=1;k<lineAsArray.length;k++) {
      
      this._data[k]._s2 = Dataset.toFloat(lineAsArray[k]);
      
    }
    
  } else if (lineAsArray[0] == 'S3') {
    
    for (var k=1;k<lineAsArray.length;k++) {
      
      this._data[k]._s3 = Dataset.toFloat(lineAsArray[k]);
      
    }
    
  } else if (lineAsArray[0] == 'S4') {
    
    for (var k=1;k<lineAsArray.length;k++) {
      
      this._data[k]._s4 = Dataset.toFloat(lineAsArray[k]);
      
    }
    
  } else if (lineAsArray[0] == 'S5') {
    
    for (var k=1;k<lineAsArray.length;k++) {
      
      this._data[k]._s5 = Dataset.toFloat(lineAsArray[k]);
      
    }
    
  } else if (lineAsArray[0] == 'S6') {
    
    for (var k=1;k<lineAsArray.length;k++) {
      
      this._data[k]._s6 = Dataset.toFloat(lineAsArray[k]);
      
    }
    
  } else if (lineAsArray[0] == 'mean') {
    
    for (var k=1;k<lineAsArray.length;k++) {
      
      this._data[k]._mean = Dataset.toFloat(lineAsArray[k]);
      
    }
    
  }    
  
}


Data = function() {
  
  this._time = 0;
  this._lvEndo = 0;
  this._lvEpi = 0;
  this._bloodpool = 0;
  this._myo = 0;
  this._roi1 = 0;
  this._roi2 = 0;
  this._roi3 = 0;
  this._roi4 = 0;
  this._lvBlood = 0;
  this._s1 = 0;
  this._s2 = 0;
  this._s3 = 0;
  this._s4 = 0;
  this._s5 = 0;
  this._s6 = 0;
  this._mean = 0;  

  
}
