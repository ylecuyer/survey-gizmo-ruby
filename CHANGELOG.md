# Versions

## 6.2.10
* Fix question pipe parsing when there's an integer without quotes instead of a quoted string

## Major Changes in 6.x
* **BREAKING CHANGE**: SurveyGizmo changed the authentication so you need to configure `api_token` and `api_token_secret` instead of user and password.
* **BREAKING CHANGE**: Pester has been removed as the retry source in favor of `Retriable`.
* FEATURE: `Configuration#region` will configure the region to use the corresponding api and time zone. (#74)
* Bugfix: fix escaping to resolve duplicate option issue (#75)
* Bugfix: fix manual pagination (#82)

## Major Changes in 5.x

* **BREAKING CHANGE**: `.all` returns an `Enumerator`, not an `Array`. This will break your code if you are using the return value of `.all` without iterating over it.
* **BREAKING CHANGE**: `SurveyCampaign` has been renamed `Campaign` to be in line with the other model names.
* FEATURE: `.all` will automatically paginate responses for you with the `:all_pages` option. There are also some built in methods like `Survey#responses` that will auto paginate.
* FEATURE: Built in retries. 1 retry with a 60 second backoff is the default but can be configured.
* FEATURE: `Response#parsed_answers` returns an array of `Answers` (new class) that are sane, stable Ruby objects instead of the sort of wild and wooly way SurveyGizmo has chosen to represent survey responses.

## Major Changes in 4.x

* **BREAKING CHANGE**: There is no more error tracking.  If the API gives an error or bad response, an exception will be raised.
* **BREAKING CHANGE**: There is no more ```copy``` method

## Major Changes in 3.x

* **BREAKING CHANGE**: Configuration is completely different
* Important Change: Defaults to using the v4 SurveyGizmo API endpoint to take advantage of various API bug fixes (notably team ownership is broken in v3)

## Old versions

[Version 2.0.1 for the v3 API is here](https://github.com/RipTheJacker/survey-gizmo-ruby/releases/tag/v2.0.1)

[Version 1.0.5 for the v2 API is here](https://github.com/RipTheJacker/survey-gizmo-ruby/releases/tag/v1.0.5)

[Version 0.7.0 for the v1 API is here](https://github.com/RipTheJacker/survey-gizmo-ruby/releases/tag/v0.7.0)
