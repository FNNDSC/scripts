$(document).ready(function() {
	initBrowserWarning();
	initDnD();
	
	database = new Database();
	
});

function error(message) {
  
  $("#upload-status-text").html(message);
  
};

function debug(message) {
  
  window.console.log(message);
 
  
};

/**
 * 
 * Inspired by http://imgscalr.com - THANKS!!
 * 
 */
function initBrowserWarning() {
	var isChrome = navigator.userAgent.toLowerCase().indexOf('chrome') > -1;
	var isFirefox = navigator.userAgent.toLowerCase().indexOf('firefox') > -1;
	
	if(!isChrome && !isFirefox)
		$("#browser-warning").fadeIn(125);
};

function initDnD() {
	// Add drag handling to target elements
	document.getElementById("body").addEventListener("dragenter", onDragEnter, false);
	document.getElementById("drop-box-overlay").addEventListener("dragleave", onDragLeave, false);
	document.getElementById("drop-box-overlay").addEventListener("dragover", noopHandler, false);
	
	// Add drop handling
	document.getElementById("drop-box-overlay").addEventListener("drop", onDrop, false);
	
	// init the widgets
	$("#upload-status-progressbar").progressbar();
};

function noopHandler(evt) {
	evt.stopPropagation();
	evt.preventDefault();
};

function onDragEnter(evt) {
	$("#drop-box-overlay").fadeIn(125);
	$("#drop-box-prompt").fadeIn(125);
};

function onDragLeave(evt) {
	/*
	 * We have to double-check the 'leave' event state because this event stupidly
	 * gets fired by JavaScript when you mouse over the child of a parent element;
	 * instead of firing a subsequent enter event for the child, JavaScript first
	 * fires a LEAVE event for the parent then an ENTER event for the child even
	 * though the mouse is still technically inside the parent bounds. If we trust
	 * the dragenter/dragleave events as-delivered, it leads to "flickering" when
	 * a child element (drop prompt) is hovered over as it becomes invisible,
	 * then visible then invisible again as that continually triggers the enter/leave
	 * events back to back. Instead, we use a 10px buffer around the window frame
	 * to capture the mouse leaving the window manually instead. (using 1px didn't
	 * work as the mouse can skip out of the window before hitting 1px with high
	 * enough acceleration).
	 */
	if(evt.pageX < 10 || evt.pageY < 10 || $(window).width() - evt.pageX < 10  || $(window).height - evt.pageY < 10) {
		$("#drop-box-overlay").fadeOut(125);
		$("#drop-box-prompt").fadeOut(125);
	}
};

function onDrop(evt) {
	// Consume the event.
	noopHandler(evt);
	
	// Hide overlay
	$("#drop-box-overlay").fadeOut(0);
	$("#drop-box-prompt").fadeOut(0);
	
	// Empty status text
	$("#upload-details").html("");
	
	// Reset progress bar incase we are dropping MORE files on an existing result page
	$("#upload-status-progressbar").progressbar({value:0});
	
	// Show progressbar
	$("#upload-status-progressbar").fadeIn(0);
	
	// Get the dropped files.
	var files = evt.dataTransfer.files;
	
	// If anything is wrong with the dropped files, exit.
	if(typeof files == "undefined" || files.length == 0)
		return;
	
	// Update and show the upload box
	var label = (files.length == 1 ? " file" : " files");
	$("#upload-count").html(files.length + label);
	$("#upload-thumbnail-list").fadeIn(125);
	
	// Process each of the dropped files individually
	for(var i = 0, length = files.length; i < length; i++) {
		uploadFile(files[i], length);
	}
	
};

function uploadFile(file, totalFiles) {
	var reader = new FileReader();
	
	// Handle errors that might occur while reading the file (before upload).
	reader.onerror = function(evt) {
		var message;
		
		// REF: http://www.w3.org/TR/FileAPI/#ErrorDescriptions
		switch(evt.target.error.code) {
			case 1:
				message = file.name + " not found.";
				break;
				
			case 2:
				message = file.name + " has changed on disk, please re-try.";
				break;
				
			case 3:
				messsage = "Upload cancelled.";
				break;
				
			case 4:
				message = "Cannot read " + file.name + ".";
				break;
				
			case 5:
				message = "File too large for browser to upload.";
				break;
		}
		
		error(message);
	}
	
  reader.onload = (function(file) {
    
    return function(e) {
      
      var data = e.target.result;
      
      var base64StartIndex = data.indexOf(',') + 1;      
      
      database.parseAndAddFile(file.name, window.atob(data.substring(base64StartIndex)));
      
      updateAndCheckProgress(totalFiles);
      
    };
  })(file);
	
	// Start reading the image off disk into a Data URI format.
	reader.readAsDataURL(file);
};

/**
 * Used to update the progress bar and check if all uploads are complete. Checking
 * progress entails getting the current value from the progress bar and adding
 * an incremental "unit" of completion to it since all uploads run async and
 * complete at different times we can't just update in-order.
 * 
 * This is only ever meant to be called from an upload 'success' handler.
 */
function updateAndCheckProgress(totalFiles, altStatusText) {
	var currentProgress = $("#upload-status-progressbar").progressbar("option", "value");
	currentProgress = currentProgress + (100 / totalFiles);
	
	// Update the progress bar
	$("#upload-status-progressbar").progressbar({value: currentProgress});
	
	// Check if that was the last file and hide the animation if it was
	if(currentProgress >= 99) {
		$("#upload-status-text").html((altStatusText ? altStatusText : "Please wait.."));

    setTimeout(function() {
      
      $("#upload-box").fadeOut(300);
      $("#upload-animation").hide();      
      calculateAndShowResults();},1000);
	}
};


function toggleContent(name) {
  
  $('#CONTENT_'+name).slideToggle();
  $('#COLLAPSE_'+name).toggle();
  $('#EXPAND_'+name).toggle();
  
};

function showToggler(name) {
  
  
  output = "<img id='COLLAPSE_"+name+"'src='icon_collapse.gif' style='align:top; cursor:pointer;' onClick='javascript:toggleContent(\""+name+"\");'>";
  output += "<img id='EXPAND_"+name+"'src='icon_expand.gif' style='align:top; cursor:pointer; display:none;' onClick='javascript:toggleContent(\""+name+"\");'>";
  return output;
};

function showPatientInformationTable(c) {
  
  output = "<table cellpadding=\"3\" cellspacing=\"3\" width=\"100%\">";
  output += "<tr>";
  output += "<td>Patient name:</td><td><b>" + c._patient._name + "</b></td>";
  output += "<td>Birth date:</td><td><b>" + c._patient._birthday + "</b></td>";
  output += "</tr>";
  output += "<tr>";
  output += "<td>Patient ID:</td><td><b>" + c._patient._id + "</b></td>";
  output += "<td>Patient weight:</td><td><b>" + c._patient._weight + "</b></td>";
  output += "</tr>";
  output += "<tr>";
  output += "<td>Patient gender:</td><td><b>" + c._patient._gender + "</b></td>";
  output += "<td>Patient height:</td><td><b>" + c._patient._height + "</b></td>";
  output += "</tr>";
  output += "</table>";
  
  return output;
  
}

function drawSmallDiagramsCols(row,d_title,caze,data,dataId) {
  
  for (d in data) {
    
    var dData = data[d];
    
    var diagramDiv = $("<td id='"+d_title.toUpperCase()+d+"_"+caze._name+"_"+dataId+"'  class='diagramCell'>");
    row.append(diagramDiv);
    
    
    var diagramData = new google.visualization.DataTable();
    diagramData.addColumn('number', 'time [ms]');
    diagramData.addColumn('number', 'intensity [au]');

    // grab the data array
    var dataarray = dData._data.slice(1);
    // map it to two strings
    var xs = "";
    var datas = "";
    dataarray.map(function(v) {
      
      // v is a Dataset.Data structure
      xs += v._time+",";
      datas += eval('v._'+dataId)+",";
      
    });
    
    var dataString = 'xs='+xs+'&datas='+datas;
    
    ajaxResponse = "";
    
    // now query the server for the levenberg-marquadt fitting
    $.ajax({
      url: 'serverside/fit.php',
      cache: false,
      type: 'GET',
      async: false,
      data: dataString,
      success: function(values){
        ajaxResponse = values; 
      }
    });
    
    var values = ajaxResponse.split(',');
    var A = parseFloat(values[0]);
    var B = parseFloat(values[1]);
    var T1star = parseFloat(values[2]);
    
    var T1 = T1star*((B/A)-1);
       
    // attach T1 for later
    eval('dData._'+dataId+'T1='+T1);    
    
    for (d2 in dataarray) {
      
      d2 = dataarray[d2];

      diagramData.addRow([d2._time, eval('d2._'+dataId)]);   
      
    } 
      
    var diagramOptions = {title:d_title+' '+d,curveType: "function",legend:'none',backgroundColor:{strokeWidth:'1'},
      width: 200, height: 100,theme:'maximized',
      vAxis: {title: '[au]'},hAxis: {title:'[ms]'}}      
    
    new google.visualization.LineChart(document.getElementById(d_title.toUpperCase()+d+'_'+caze._name+"_"+dataId)).
    draw(diagramData, diagramOptions);      
    
  }      
  
};

function drawSmallDiagrams(firsttable,caze, title) {
  
  var row = $("<tr>");
  firsttable.append(row);
  
  var labelcell = $("<td class='diagramCell'></td>");
  labelcell.html('<b>'+title+'</b>');
  row.append(labelcell);
  
  var dataId = 'lvBlood';
  if (title != 'LV Blood') {
    
    dataId = title.toLowerCase();
    
  }
  
  drawSmallDiagramsCols(row,'Precontrast',caze,caze._precontrast,dataId);
  drawSmallDiagramsCols(row,'Postcontrast',caze,caze._postcontrast,dataId);
  
}


function drawBigDiagrams(table,caze, title) {
  
  var row = $("<tr>");
  table.append(row);
  
  var labelcell = $("<td class='diagramCell'></td>");
  labelcell.html('<b>'+title+'</b>');
  row.append(labelcell);

  dataId = title.toLowerCase();
   
  
  var diagramcell = $("<td id='BIGDIAGRAM_"+caze._name+"_"+dataId+"'  class='diagramCell'>");
  row.append(diagramcell);
  
  var resultcell = $("<td id='RESULTCELL_"+caze._name+"_"+dataId+"' class='resultCell'>");
  row.append(resultcell);
  
  var diagramData = new google.visualization.DataTable();
  diagramData.addColumn('number', 'R1_Blood'); 
  diagramData.addColumn('number', 'R1_'+title);

  
  // pre contrast
  for (pre in caze._precontrast) {
    
    pre = caze._precontrast[pre];
    
    x_pre = pre._lvBloodT1;
    y_pre = eval('pre._'+dataId+'T1');
    
    diagramData.addRow([x_pre,y_pre]); 
    
  }
  
  // post contrast
  for (post in caze._postcontrast) {
    
    post = caze._postcontrast[post];
    
    x_post = post._lvBloodT1;
    y_post = eval('post._'+dataId+'T1');
    
    diagramData.addRow([x_post, y_post ]);     
    
  } 
  
  var lambda = (y_post - y_pre) / (x_post - x_pre);
  eval('caze._'+dataId+'Lambda='+lambda);
  
  
  var diagramOptions = {title:'R1_' + title + ' - f(R1_Blood)',curveType: "function",legend:'none',backgroundColor:{strokeWidth:'1'},
                        width: 200, height: 100,theme:'maximized',
                        vAxis: {title: 'R1_'+title},hAxis: {title:'R1_Blood'}}      
                      
  new google.visualization.ScatterChart(document.getElementById('BIGDIAGRAM_'+caze._name+"_"+dataId)).
  draw(diagramData, diagramOptions);        
  
  
}

function calcResults(caze, title) {
  
  var vecoutput = "No HCT value!";

  console.log(caze);
  
  
  dataId = title.toLowerCase();  
  
  if (caze._hct != -1) {
     
    var lambda = eval('caze._'+dataId+'Lambda');
    
    var vec = lambda*(1-caze._hct)-0.045;
    
    vecoutput = $('<h6>vec: '+vec+'</h6>');
    
  }
  
  console.log('#RESULTCELL_'+caze._name+'_'+dataId+'::' + vecoutput);
  
  $('#RESULTCELL_'+caze._name+'_'+dataId).append(vecoutput);
  
  
}

function calc(cazename) {
  
  var c = database._cases[cazename];
  
  calcResults(c,'S1');
  calcResults(c,'S2');
  calcResults(c,'S3');
  calcResults(c,'S4');
  calcResults(c,'S5');
  calcResults(c,'S6');
  calcResults(c,'mean');  
  
}

function updateAndCalc(cazename) {
  
  var c = database._cases[cazename];
  
  c._hct = parseFloat($('#HCT_'+cazename).val());
  
  calc(cazename);
  
}

function calculateAndShowResults() {
  
  var cases = database._cases;
  
  for (c in cases) {
    c = cases[c];
    var patientName = c._patient._name;
    
    // create the container
    var cDiv = $("<div id='RESULT_"+c._name+"' class='resultsBox'></div>");
    $("#results").append(cDiv);
    cDiv.html("&nbsp;"+showToggler(c._name)+"<span class='resultsHeader' onClick='javascript:toggleContent(\""+c._name+"\");'>&nbsp;" + patientName + "</span><span class='smallInputsLabel'>HCT-Value:<input class='smallInputs' onChange=\"updateAndCalc('"+c._name+"')\" type='text' id='HCT_"+c._name+"'></span>");
    
    var contentDiv = $("<div id='CONTENT_"+c._name+"' class='content'></div>");
    cDiv.append(contentDiv);
    
    
    // now we fill the actual content
    
    // patient information
    var patientDiv = $("<div></div>");
    contentDiv.append(patientDiv);
    patientDiv.html(showPatientInformationTable(c));
    contentDiv.append('<br><br>');
    
    // diagrams
    var firsttable = $("<table>").attr('id','FIRSTTABLE_'+c._name);
    contentDiv.append(firsttable);
    
    drawSmallDiagrams(firsttable, c, 'LV Blood');
    drawSmallDiagrams(firsttable, c, 'S1');
    drawSmallDiagrams(firsttable, c, 'S2');
    drawSmallDiagrams(firsttable, c, 'S3');
    drawSmallDiagrams(firsttable, c, 'S4');
    drawSmallDiagrams(firsttable, c, 'S5');
    drawSmallDiagrams(firsttable, c, 'S6');
    drawSmallDiagrams(firsttable, c, 'Mean');
    contentDiv.append('<br><br>');    

    contentDiv.append('<h5>Extracellular Volume Fraction</h5>')
    var secondtable = $("<table>").attr('id','SECONDTABLE_'+c._name);
    contentDiv.append(secondtable);    
    drawBigDiagrams(secondtable,c,'S1');
    drawBigDiagrams(secondtable,c,'S2');
    drawBigDiagrams(secondtable,c,'S3');
    drawBigDiagrams(secondtable,c,'S4');
    drawBigDiagrams(secondtable,c,'S5');
    drawBigDiagrams(secondtable,c,'S6');
    drawBigDiagrams(secondtable,c,'Mean');
    contentDiv.append('<br><br>');        
       
    calc(c._name);
    
  }
  
};


