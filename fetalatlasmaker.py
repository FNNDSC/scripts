import os
import shutil
import subprocess

input_path = '/chb/users/daniel.haehn/Downloads/fetAtlas/'
output_folder = '/chb/users/daniel.haehn/tmp8'


structures = {
              25: 'csf',
              41:'cortex',
              73:'hemispheres',
              107:'ventricles'
              }

shutil.rmtree( output_folder, True )
os.mkdir( output_folder )

for i in range( 23, 38 ):

  output_path = output_folder + os.sep + str( i )
  os.mkdir( output_path )

  subject = str( i )

  for s in structures:

    label = str( s )
    structure = structures[s]

    cmd = 'ss;chb-fsstable;';
    cmd += 'cd ' + output_path + ';'
    cmd += 'mri_binarize --i ' + input_path + structure + '-' + subject + '.nii.gz --o ' + structure + '-' + subject + '-thresholded.nii --min 0.25 --binval ' + label + ' &&'
    cmd += 'mri_pretess ' + structure + '-' + subject + '-thresholded.nii "' + label + '" ' + input_path + structure + '-' + subject + '.nii.gz ' + structure + '-' + subject + '-pretess.nii &&'
    cmd += 'mri_tessellate ' + structure + '-' + subject + '-pretess.nii ' + label + ' ' + structure + '-' + subject + '.fsm &&'
    cmd += 'mris_smooth -nw ' + structure + '-' + subject + '.fsm ' + structure + '-' + subject + '.smooth.fsm &&'
    cmd += 'mris_convert lh.' + structure + '-' + subject + '.smooth.fsm ' + structure + '-' + subject + '.vtk &&'
    cmd += 'mris_convert -n lh.' + structure + '-' + subject + '.vtk ' + structure + '-' + subject + '.normals &&'
    cmd += 'rm lh.' + structure + '-' + subject + '.smooth.fsm &&'
    cmd += 'rm ' + structure + '-' + subject + '.fsm &&'
    cmd += 'rm ' + structure + '-' + subject + '-pretess.nii &&'
    cmd += 'cat lh.' + structure + '-' + subject + '.vtk | sed "s/  / /g" > ' + structure + '.vtk &&'
    cmd += 'rm lh.' + structure + '-' + subject + '.vtk'

    # run command
    sp = subprocess.Popen( ["/bin/bash", "-i", "-c", cmd] )
    sp.communicate()

    # now attach the normals

    normals = 'POINT_DATA '

    with open( output_path + os.sep + structure + '-' + subject + '.normals' ) as f:

      lines = f.readlines()

      number_of_normals = -1

      for i, l in enumerate( lines ):

        if i == 1:
          number_of_normals = l.split( ' ' )[0]
          normals += str( number_of_normals ) + '\n'
          normals += 'NORMALS normals float\n'

        elif i > 1 and i < int( number_of_normals ) + 2:
          # normals data coming
          _normals = l.split( '  ' )
          n_x = _normals[0]
          n_y = _normals[1]
          n_z = _normals[2]
          normals += n_x + ' ' + n_y + ' ' + n_z + '\n'

    with open( output_path + os.sep + structure + '.vtk', "a" ) as f:
      f.write( '\n' + normals )

  # now merge all label maps
  cmd = 'ss;chb-fsstable;';
  cmd += 'cd ' + output_path + ';'
  cmd += 'cp ' + input_path + 'template-' + subject + '.nii.gz template.nii.gz;'
  cmd += 'gzip -d template.nii.gz;'
  cmd += 'rm *.normals;'
  cmd += 'mri_concat --i cortex-' + subject + '-thresholded.nii ventricles-' + subject + '-thresholded.nii hemispheres-' + subject + '-thresholded.nii csf-' + subject + '-thresholded.nii --o labelmap.nii --max;'
  cmd += 'rm *thresholded*;'
  # run command
  sp = subprocess.Popen( ["/bin/bash", "-i", "-c", cmd] )
  sp.communicate()
