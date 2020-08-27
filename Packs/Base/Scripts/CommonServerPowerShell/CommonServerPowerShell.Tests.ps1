BeforeAll {
    . $PSScriptRoot\CommonServerPowerShell.ps1
}


Describe 'Check-DemistoServerRequest' {
    It 'Check that a call to demisto DemistoServerRequest mock works. Should always return an empty response' {
        global:DemistoServerRequest @{} | Should -BeNullOrEmpty
        $demisto.GetAllSupportedCommands() | Should -BeNullOrEmpty
    }
}

Describe 'Check-UtilityFunctions' {
    It "ArgToList" {
        $r = argToList "a,b,c,2"
        $r.GetType().IsArray | Should -BeTrue
        $r[0] | Should -Be "a"
        $r.Length | Should -Be 4
        $r = argToList '["a","b","c",2]'
        $r.GetType().IsArray | Should -BeTrue
        $r[0] | Should -Be "a"
        $r[3] | Should -Be 2
        $r.Length | Should -Be 4
        $r = argToList @("a","b","c",2)
        $r.GetType().IsArray | Should -BeTrue
        $r[0] | Should -Be "a"
        $r[3] | Should -Be 2
        $r.Length | Should -Be 4
        $r = argToList "a"
        $r.GetType().IsArray | Should -BeTrue
        $r[0] | Should -Be "a"
        $r.Length | Should -Be 1
    }

    It "ReturnOutputs" {
        $msg = "Human readable"
        $r = ReturnOutputs $msg @{Test="test"} @{Raw="raw"}
        $r.ContentsFormat | Should -Be "json"
        $r.HumanReadable | Should -Be $msg
        $r.EntryContext.Test | Should -Be "test"
        $r.Contents.Raw | Should -Be "raw"
        $r = ReturnOutputs $msg
        $r.ContentsFormat | Should -Be "text"
        $r.Contents | Should -Be $msg
    }

    It "ReturnOutputs PsCustomObject" {
        $msg = "Human readable"
        $output = [PsCustomObject]@{Test="test"}
        $raw = [PSCustomObject]@{Raw="raw"}
        $r = ReturnOutputs $msg  $output $raw
        $r.ContentsFormat | Should -Be "json"
        $r.HumanReadable | Should -Be $msg
        $r.EntryContext.Test | Should -Be "test"
        $r.Contents.Raw | Should -Be "raw"
        $r = ReturnOutputs $msg
        $r.ContentsFormat | Should -Be "text"
        $r.Contents | Should -Be $msg
    }

    It "ReturnError simple" {
        $msg = "this is an error"
        $r = ReturnError $msg
        $r.ContentsFormat | Should -Be "text"
        $r.Type | Should -Be 4
        $r.Contents | Should -Be $msg
        $r.EntryContext | Should -BeNullOrEmpty
    }
    Context "Check log function" {
        BeforeAll {
            Mock DemistoServerLog {}
        }

        It "ReturnError complex" {
            # simulate an error
            Test-JSON "{badjson}" -ErrorAction SilentlyContinue -ErrorVariable err
            $msg = "this is a complex error"
            $r = ReturnError $msg $err @{Failed = $true}
            $r.Contents | Should -Be $msg
            $r.EntryContext.Failed | Should -BeTrue
            # ReturnError call demisto.Error() make sure it was called
            Assert-MockCalled -CommandName DemistoServerLog -Times 2 -ParameterFilter {$level -eq "error"}
            Assert-MockCalled -CommandName DemistoServerLog -Times 1 -ParameterFilter {$msg.Contains("Cannot parse the JSON")}
        }
    }
    Context "ConvertTo-Markdown" {
        BeforeAll {
            $HashTableWithTwoEntries = @(
            @{
                Index = '0'
                Name = 'First element'
            },
            @{
                Index = '1'
                Name = 'Second element'
            }
            )
            $HashTableWithOneEntry = @(
            @{
                Index = '0'
                Name = 'First element'
            })
            $OneElementObject = @()
            ForEach ($object in $HashTableWithOneEntry)
            {
                $OneElementObject += New-Object PSObject -Property $object
            }
            $TwoElementObject = @()
            ForEach ($object in $HashTableWithTwoEntries)
            {
                $TwoElementObject += New-Object PSObject -Property $object
            }
        }
        It "Empty list without a name" {
            ConvertTo-Markdown @() | Should -Be "**No entries.**`n"
        }
        It "A list with one element and no name" {
            ConvertTo-Markdown $OneElementObject | Should -Be "Index | Name`n--- | ---`n0 | First element`n"
        }
        It "A list with two elements and no name" {
            ConvertTo-Markdown $TwoElementObject | Should -Be "Index | Name`n--- | ---`n0 | First element`n1 | Second element`n"
        }
        It "Empty list with a name" {
            ConvertTo-Markdown @() "Test Name" | Should -Be "### Test Name`n**No entries.**`n"
        }
        It "A list with two elements and a name" {
            ConvertTo-Markdown $TwoElementObject "Test Name" | Should -Be "### Test Name`nIndex | Name`n--- | ---`n0 | First element`n1 | Second element`n"
        }
        It "A list with one elements and a name" {
            ConvertTo-Markdown $OneElementObject "Test Name" | Should -Be "### Test Name`nIndex | Name`n--- | ---`n0 | First element`n"
        }
    }
}
