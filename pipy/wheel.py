class WheelValidationException( Exception ):

  def __init__( self, wheelName, input ):
    self.input = input
    super( WheelValidationException, self ).__init__( 'Hole-in-bucket for ' + str( wheelName ) + ': "' + str( input ) + '" missing..' )

class Wheel:

  def __init__( self, bucket, inputs, outputs ):
    self.__bucket = bucket
    self.__inputs = inputs
    self.__outputs = outputs
    self.__validate()

  def outputs( self ):
    return self.__outputs

  def inputs( self ):
    return self.__inputs

  def spin( self ):
    pass

  def __validate( self ):

    for i in self.__inputs:

      # split for default value
      splittedInput = i.partition( '=' )

      if self.__bucket.get( splittedInput[0] ):
        # input is in bucket
        continue
      else:
        # input is not in bucket
        # check if we have a default value
        if splittedInput[1] == "=":
          # yes we do!
          # put the default value in the bucket
          self.__bucket.put( splittedInput[0], splittedInput[2] )
        else:
          # error - information missing to run this wheel!
          raise WheelValidationException( self, i )
