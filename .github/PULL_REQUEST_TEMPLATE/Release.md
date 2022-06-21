Prepares [<paste release version>](<paste milestone link>) release.




## Checklist

- Created PR:
    - [ ] In [draft mode][l:1]
    - [ ] Name contains issue reference
    - [ ] Name contains milestone reference
    - [ ] Has type and `k::` labels applied
- Before [review][l:4]:
    - [ ] Documentation is updated (if required)
    - [ ] Tests are updated (if required)
    - [ ] Changes conform [code style][l:2]
    - [ ] [CHANGELOG entries][l:3] are verified and corrected
        - [ ] [Deployment instructions][l:3] are verified and corrected (if required)
    - [ ] FCM (final commit message) is posted or updated
    - [ ] [Draft mode][l:1] is removed
- [ ] [Review][l:4] is completed and changes are approved
    - [ ] FCM (final commit message) is approved
- Before merge:
    - [ ] Milestone is set
    - [ ] PR's name and description are correct and up-to-date
    - [ ] All temporary labels are removed




[l:1]: https://help.github.com/en/articles/about-pull-requests#draft-pull-requests
[l:2]: /CONTRIBUTING.md#code-style
[l:3]: /CHANGELOG.md
[l:4]: https://help.github.com/en/articles/reviewing-changes-in-pull-requests
