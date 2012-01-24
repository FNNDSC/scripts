import pipeline_status

pipelineStagesDict = { 
                    'tract' : 
                        { 'inputs' : 
                            { 'dcm' : 'dir/filename.dcm'},
                          'outputs' :
                            { 'trk' : 'dir/dir/filename.trk',
                              'fa'  : 'dir/filename_fa.nii'}
                        },
                    'freesurfer' :
                        {  'inputs' : 
                            { 'dcm' : 'dir/filename.dcm'},
                          'outputs' :
                            { 'trk' : 'dir/dir/filename.trk',
                              'fa'  : 'dir/filename_fa.nii'}
                         }                                    
                      }

ps = pipeline_status.PipelineStatus()
ps.Pipeline.name = 'connectome'
stage1 = ps.AddStage('dicom_seriesCollect.bash')
# Exec can run - will be true, no inputs
# Now you would run stage 1 and check the log file for output filename
dcmT1Output = ps.AddStageOutput(stage = stage1, 
                                rootDir = '/chb/osx1927/1/users/dicom/postproc/projects/ginsburg/Anonymous-20080811_UNKNOWN_AGE-20100528-1275052813128852248-connectome/', 
                                outputFilePath = 'dir_from_logfile/file_from_logfile.dcm', 
                                outputName = 'dcm' )

stage2 = ps.AddStage('tract')
# Exec can run - will be true, no inputs
trkOutput = ps.AddStageOutput(stage = stage2, 
                              rootDir = '/chb/osx1927/1/users/dicom/postproc/projects/ginsburg/Anonymous-20080811_UNKNOWN_AGE-20100528-1275052813128852248-connectome/tract_meta-stage2-dcm2trk.bash/final-trackvis/', 
                              outputFilePath = '*.trk', 
                              outputName = 'trk' )
faOutput = ps.AddStageOutput(stage = stage2, 
                              rootDir = '/chb/osx1927/1/users/dicom/postproc/projects/ginsburg/Anonymous-20080811_UNKNOWN_AGE-20100528-1275052813128852248-connectome/tract_meta-stage2-dcm2trk.bash/final-trackvis/', 
                              outputFilePath = '*_fa.nii', 
                              outputName = 'fa' )
b0Output = ps.AddStageOutput(stage = stage2, 
                              rootDir = '/chb/osx1927/1/users/dicom/postproc/projects/ginsburg/Anonymous-20080811_UNKNOWN_AGE-20100528-1275052813128852248-connectome/tract_meta-stage2-dcm2trk.bash/final-trackvis/', 
                              outputFilePath = '*_b0.nii', 
                              outputName = 'b0' )

stage3 = ps.AddStage('register')
ps.AddStageInputFromObject(stage3, dcmT1Output)
ps.AddStageInputFromObject(stage3, b0Output)

# Exec can run
print ps.CanRun(stage3)
print ps.RanOK(stage1)
# Set outputs

ps.SaveToFile('connectome.status')
ps.LoadFromFile('connectome.status')