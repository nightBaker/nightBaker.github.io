---
layout: post
title:  Gitflow + Nuget + Azure pipelines painlessly.
date:   2019-12-24
summary:  How to set up gitflow workflow for nuget package development with azure pipelines.
categories: gitflow azure piplines 
---

## Gitflow

[**Gitflow**](https://docs.microsoft.com/en-us/azure/architecture/framework/devops/gitflow-branch-workflow) is git workflow, which dictates how to work with branches in large projects.  
<IMG width="800" src="https://nvie.com/img/git-model%402x.png"/>

## Gitflow for nuget package development

* Every time, when our **devel** branch is updated, we have to create **beta** version of nuget package.
* When **release** branch is created, we have to publish **Release Candidate (rc)** version of nuget package.
* When **master** is updated, we release new version of package.
* Sometimes, we don't want to update devel branch, however we want to test new package version. In this situation, we can use `git tag` to mark any commit with tag.
 In our pipeline we can subcsribe for tag trigger and publish **alpha** version of nuget package. 
* When **hotfix** branch is updated, it should be merge to devel and master


## Prerequisites

* Create azure devops account
* Create project
* Create variables group. We need two variables `Mijor` and `Minor` with `0` and `1` values respectively.
![azure devops create variables group]({{ "/images/azure-nuget-pipeline/create-variables-group.png" | absolute_url }})

## Beta 

Let's create `azure-pipelines.devel.yml` file with content.

```yaml


trigger:
  branches:
    include:    
    - devel  

pool:
  vmImage: 'windows-latest'

variables:
- group: Pipelines variables  
- name: 'patch'
  value: $[counter(variables['Minor'], 0)]
- name: 'NugetVersionBeta'
  value : $(Major).$(Minor).$(patch)-beta


name: $(Major).$(Minor).$(patch)

steps:
- task: NuGetToolInstaller@1
  displayName: 'Installing nuget tool'

- task: NuGetCommand@2
  displayName: 'Restoring nugets'
  inputs:
    restoreSolution: '**/*.sln'

- task: DotNetCoreCLI@2
  displayName: 'Packing library'
  condition: succeeded()
  inputs:
    command: 'pack'
    packagesToPack: '**/Azure.Pipelines.Package.csproj'
    versioningScheme: 'byEnvVar'
    versionEnvVar: 'NugetVersionBeta'

- task: DotNetCoreCLI@2
  displayName: 'Pushing packages'
  condition: and( succeeded(), ne(variables['Build.Reason'], 'PullRequest'))
  inputs:
    command: 'push'
    packagesToPush: '$(Build.ArtifactStagingDirectory)/*.nupkg'
    nuGetFeedType: 'internal'
    publishVstsFeed: 'feed-id'

```

Let's consider this pipeline in details.

1. 
```yaml
trigger:
  branches:
    include:    
    - devel  

```

This part configures build trigger. Build pipeline runs when **devel** branch is updated. 

2. 

```yaml
variables:
- group: Pipelines variables  
- name: 'patch'
  value: $[counter(variables['Minor'], 0)]
- name: 'NugetVersionBeta'
  value : $(Major).$(Minor).$(patch)-beta
```

As you noticed, we use variables group with predefined `Major` and `Minor` variables. However, we have countable variable `patch`.
 Here we use [counter](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/expressions?view=azure-devops#counter) function. It will be incremented every build while variable `Minor` stay the same, i.e. it will be reset after `Minor` is changed.

3.

```yaml
- task: DotNetCoreCLI@2
  displayName: 'Packing library'
  condition: succeeded()
  inputs:
    command: 'pack'
    packagesToPack: '**/Azure.Pipelines.csproj'
    versioningScheme: 'byEnvVar'
    versionEnvVar: 'NugetVersionBeta'
```

In this part, we use previously defined environment variable `NugetVersionBeta`, which always has postfix `beta`

## Release

### Release creation
Firstly, we should create release from *devel* branch. Let's create `azure-pipelines.create-release.yml` file. This pipeline we can run only manually.

```yaml
trigger: none

pool:
  vmImage: 'windows-latest'

variables:
- group: Pipelines variables

name: $(Major).$(Minor)-open

steps:

- checkout: self
  persistCredentials: true
- task: CmdLine@2
  displayName: 'Creating new release branch'
  inputs:
    script: |      
      git fetch
      git checkout devel
      git branch release/$(Major).$(Minor)
      git checkout release/$(Major).$(Minor)
      git push --set-upstream origin release/$(Major).$(Minor)
    failOnStderr: false
```


### Release branch
After release branch is created, it triggers build pipeline. Create new file `azure-pipelines.release.yml`.


```yaml
trigger:
  branches:
    include:    
    - release/*    


pool:
  vmImage: 'windows-latest'

variables:
- group: Pipelines variables
- name: 'patch'
  value: $[counter(variables['Minor'], 0)] #this will reset when we bump minor
- name: 'NugetVersion' 
  value : $(Major).$(Minor).$(patch)-rc


name: $(Major).$(Minor).$(patch)

steps:
- task: NuGetToolInstaller@1
  displayName: 'Installing nuget tool'

- task: NuGetCommand@2
  displayName: 'Restoring nugets'
  inputs:
    restoreSolution: '**/*.sln'
   
- task: DotNetCoreCLI@2  
  displayName: 'Packing client library'
  condition: succeeded()
  inputs:
    command: 'pack'
    packagesToPack: '**/Azure.Pipelines.csproj'
    versioningScheme: 'byEnvVar'
    versionEnvVar: 'NugetVersion'


- task: DotNetCoreCLI@2
  displayName: 'Pushing packages'
  condition: and( succeeded(), ne(variables['Build.Reason'], 'PullRequest'))
  inputs:
    command: 'push'
    packagesToPush: '$(Build.ArtifactStagingDirectory)/*.nupkg'
    nuGetFeedType: 'internal'
    publishVstsFeed: 'feed-id'
```

As you can see, our nuget version has postfix `rc`.

### Release closing

When we tested our release, we have to close this branch and merge it to *master* branch with tag and *devel* branch. Let's create new file `azure-pipelines.create-close.yml`. The pipeline also can be run only manually.

```yaml
trigger: none

pool:
  vmImage: 'windows-latest'

variables:
- group: Pipelines variables

name: $(Major).$(Minor)-close

steps:

- checkout: self
  persistCredentials: true

- task: CmdLine@2
  displayName: 'Merge to master'
  inputs:
    script: |                          
      git checkout master
      git merge origin/release/$(Major).$(Minor) -m "merge to master"
      git status
      git tag v$(Major).$(Minor)
      git push 
      git push --tag
      git status
    failOnStderr: false

- task: CmdLine@2
  displayName: 'Merge to devel'
  inputs:
    script: |                 
      git checkout devel
      git merge origin/release/$(Major).$(Minor) -m "merge to devel"
      git status
      git push 
      git status
    failOnStderr: false

```

## Master branch

If *master* is updated, new version of nuget package is published. Create `azure-pipelines.yml` file.

```yaml

trigger:
  branches:
    include:    
    - master   

pool:
  vmImage: 'windows-latest'

variables:
- group: Pipelines variables  
- name: 'patch'
  value: $[counter(variables['Minor'], 0)] #this will reset when we bump minor  
- name: 'NugetVersion'
  value : $(Major).$(Minor).$(patch)


name: $(Major).$(Minor).$(patch)

steps:
- task: NuGetToolInstaller@1
  displayName: 'Installing nuget tool'

- task: NuGetCommand@2
  displayName: 'Restoring nugets'
  inputs:
    restoreSolution: '**/*.sln'

- task: DotNetCoreCLI@2
  displayName: 'Packing library'
  condition: succeeded()
  inputs:
    command: 'pack'
    packagesToPack: '**/Azure.Pipelines.Package.csproj'
    versioningScheme: 'byEnvVar'
    versionEnvVar: 'NugetVersion'

- task: DotNetCoreCLI@2
  displayName: 'Pushing packages'
  condition: and( succeeded(), ne(variables['Build.Reason'], 'PullRequest'))
  inputs:
    command: 'push'
    packagesToPush: '$(Build.ArtifactStagingDirectory)/*.nupkg'
    nuGetFeedType: 'internal'
    publishVstsFeed: 'feed-id'
```


## Alpha versions

For alpha versions we use tag trigger for any `alpha*` tag. Create `azure-pipelines.alpha-nuget.yml` file.

```yaml


trigger:  
  tags: 
    include:
    - alpha*

pool:
  vmImage: 'windows-latest'


variables:
- group: Pipelines variables
- name: 'patch'
  value: $[counter(variables['Minor'], 0)] #this will reset when we bump minor
- name: 'NugetVersion' 
  value : $(Major).$(Minor).$(patch)-alpha 


name: $(Major).$(Minor).$(patch)-alpha

steps:

- task: NuGetToolInstaller@1

- task: NuGetCommand@2
  inputs:
    restoreSolution: '**/*.sln'

- task: DotNetCoreCLI@2
  displayName: 'Packing'
  condition:  succeeded()
  inputs:
    command: 'pack'
    packagesToPack: '**/Azure.Pipelines.Package.csproj'
    versioningScheme: 'byEnvVar'
    versionEnvVar: 'NugetVersion'

- task: DotNetCoreCLI@2
  displayName: 'Pushing'
  inputs:
    command: 'push'
    packagesToPush: '$(Build.ArtifactStagingDirectory)/*.nupkg'
    nuGetFeedType: 'internal'
    publishVstsFeed: 'feed id'

```

## Hotfixes

if we have hotfix branch, it should be merged to *devel* and *master* branches. Create `azure-pipelines.hotfixes.yml` file.

```yaml
trigger:
  branches:
    include:    
    - hotfix/*

pool:
  vmImage: 'windows-latest'

variables:
- group: Pipelines variables

name: $(Major).$(Minor)-hotfix

steps:

- checkout: self
  persistCredentials: true

- task: CmdLine@2
  displayName: 'Merge to master'
  inputs:
    script: |                          
      git checkout master
      git merge $(Build.SourceBranchName) -m "merge to master"
      git status      
      git push       
      git status
    failOnStderr: false

- task: CmdLine@2
  displayName: 'Merge to devel'
  inputs:
    script: |                 
      git checkout devel
      git merge $(Build.SourceBranchName) -m "merge to devel"
      git status
      git push 
      git status
    failOnStderr: false

```

### Conclusion

Now, we have build pipelines for every branch regarding to GitFlow workflow. You can get full project [Source code](https://github.com/nightBaker/azure_pipelines)