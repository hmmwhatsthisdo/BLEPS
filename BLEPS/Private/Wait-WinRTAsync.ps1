Function Wait-WinRTAsync {
    [CmdletBinding(
    )]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [System.__ComObject[]]
        $InputObject,

        [Type]
        $OutputType,

        [System.Threading.CancellationToken]
        $CancellationToken

    )
    
    Begin {
        #region Generic Method resolver
        # Fetch all overloads of [System.WindowsRuntimeSystemExtensions]::AsTask
        $AsTask = [System.WindowsRuntimeSystemExtensions].GetMethods("Public, Static") `
        | Where-Object name -eq "AsTask"

        # Filter out AsTask overloads with the proper return type
        # Actions (no output) return [Task], operations (generic output type) return [Task<>]
        If ($null -ne $OutputType) {
            $GenericReturnType = [System.Threading.Tasks.Task`1]
        } else {
            $GenericReturnType = [System.Threading.Tasks.Task]
        }

        $AsTask = $AsTask `
        | Where-Object {$_.ReturnType.GUID -eq $GenericReturnType.GUID}

        # Filter out AsTask overloads with the proper first parameter type
        # Actions use [IAsyncAction], Operations use [IAsyncOperation<>]
        if ($null -ne $OutputType) {
            $AsyncParamType = [Windows.Foundation.IAsyncOperation`1]
        } else {
            $AsyncParamType = [Windows.Foundation.IAsyncAction]
        }

        $AsTask = $AsTask `
        | Where-Object {$_.GetParameters()[0].ParameterType.GUID -eq $AsyncParamType.GUID}

        $ParamCount = 1

        If ($null -ne $CancellationToken) {
            # Filter out AsTask overloads with a [CancellationToken] for param 2
            $AsTask = $AsTask `
            | Where-Object {$_.GetParameters()[1].ParameterType -eq [System.Threading.CancellationToken]}
            
            $ParamCount++
        }

        # Filter out AsTask overloads with unaccounted-for parameters
        $AsTask = $AsTask `
        | Where-Object {$_.GetParameters().Count -eq $ParamCount}

        If (($AsTask | Measure-Object | ForEach-Object Count) -gt 1) {
            $ex = [System.Reflection.AmbiguousMatchException]::new("Multiple [System.WindowsRuntimeSystemExtensions]::AsTask overloads found.")
            $ex.Data["MethodInfos"] = $AsTask
            throw $ex
        } elseif ($AsTask.IsGenericMethod) {
            $TaskConverter = $AsTask.MakeGenericMethod($OutputType)
        } else {
            $TaskConverter = $AsTask
        }
        #endregion

        If ($null -ne $OutputType) {
            $TaskType = [System.Threading.Tasks.Task`1].MakeGenericType($OutputType)
        } Else {
            $TaskType = [System.Threading.Tasks.Task]
        }
        $TaskCache = [System.Collections.Generic.List`1].MakeGenericType($TaskType)::new()

        Function Receive-Task {

            $TargetTasks = $TaskCache `
            | Where-Object Status -In @(
                [System.Threading.Tasks.TaskStatus]::Canceled,
                [System.Threading.Tasks.TaskStatus]::Faulted,
                [System.Threading.Tasks.TaskStatus]::RanToCompletion
            )

            $TargetTasks | ForEach-Object {
                Write-Debug "Async Task with ID $($_.Id) status: $($_.Status)"
            }

            $TargetTasks `
            | Where-Object Status -eq "Faulted" `
            | ForEach-Object {
                Write-Error -Message "WinRT Async operation failed" -Exception $_.Exception -TargetObject $_
            }

            If ($null -ne $OutputType) {
                $TargetTasks `
                | Where-Object Status -eq "RanToCompletion" `
                | ForEach-Object Result
            }

            $TargetTasks | ForEach-Object {
                $TaskCache.Remove($_) | Out-Null
            }
        
        }
        
    }
    
    Process {
        # Register all tasks in the cache
        $InputObject | ForEach-Object {
            $TaskConverter.Invoke($null, ([System.__ComObject]$_))
        } | ForEach-Object {
            $TaskCache.Add($_) | Out-Null
        }

        # Retrieve any that may have finished
        Receive-Task
    }
    
    End {

        $WaitTimeout = [timespan]::FromMilliseconds(200)

        do {

            Write-Debug "Waiting... [$($TaskCache.Count) task(s) remaining]"
            # Wait for all tasks to complete, up to 200ms
            If ($null -eq $CancellationToken) {
                [System.Threading.Tasks.Task]::WaitAll($TaskCache.ToArray(), $WaitTimeout) | Out-Null
            } Else {
                [System.Threading.Tasks.Task]::WaitAll($TaskCache.ToArray(), $WaitTimeout, $CancellationToken) | Out-Null
            }

            # Receive any tasks that have completed
            Receive-Task
            
        } until (
            $(If ($null -ne $CancellationToken) {$CancellationToken.IsCancellationRequested} Else {$false}) -or 
            $($TaskCache.Count -eq 0)
        )

    }
}