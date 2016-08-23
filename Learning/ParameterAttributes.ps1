param(
    [Parameter(Mandatory=$true)]$ParameterExampleOne,
        #Optional named parameter. True indicates the cmdlet parameter is required
        #If a required parameter is not provided when the cmdlet is invoked,
        #Windows PowerShell prompts the user for a parameter value. The default is false.

    [Parameter(Position=0)]$ParameterExampleTwo,
        #Optional named parameter. Specifies the position of the parameter within a Windows PowerShell command
    
    [Parameter(ParameterSetName="ParameterGroupingOne")]$ParameterExampleThree,
        #Optional named parameter. Specifies the parameter set that this cmdlet parameter belongs to.
        #If no parameter set is specified, the parameter belongs to all parameter sets.

    [Parameter(ValueFromPipeline=$true)]$ParameterExampleFour,
        #Optional named parameter. True indicates that the cmdlet parameter takes its value from a pipeline object.
        #Specify this keyword if the cmdlet accesses the complete object, not just a property of the object. The default is false.

    [Parameter(ValueFromPipelineByPropertyName=$true)]$ParameterExampleFive,
        #Optional named parameter. True indicates that the cmdlet parameter takes its value from a property of a pipeline object
        #that has either the same name or the same alias as this parameter.
        #For example, if the cmdlet has a Name parameter and the pipeline object also has a Name property,
        #the value of the Name property is assigned to the Name parameter of the cmdlet. The default is false

    [Parameter(ValueFromRemainingArguments=$true)]$ParameterExampleSix,
        #Optional named parameter. True indicates that the cmdlet parameter accepts all remaining arguments
        #that are passed to the cmdlet. The default is false

    [Parameter(HelpMessage="Parameter Description")]$ParameterExampleSeven,
        #Optional named parameter. Specifies a short description of the parameter.
        #Windows PowerShell displays this message when a cmdlet is run and a mandatory parameter is not specified

    [Alias("ParamEight","Param8")][Parameter(Mandatory=$true)]$ParameterExampleEight
        #The Alias attribute establishes an alternate name for the parameter.
        #There is no limit to the number of aliases that you can assign to a parameter
)

#More Info here: https://technet.microsoft.com/en-us/library/hh847743.aspx
#Or here: https://msdn.microsoft.com/en-us/library/ms714348(v=vs.85).aspx
