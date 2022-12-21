# Versions

## 8.0.0 (unreleased)
* BREAKING CHANGE: Switch from the old Survey Gizmo API URLs (`restapi.surveygizmo.com` and `restapi.surveygizmo.eu`) to the new Alchemer API URLs (`api.alchemer.com` and `api.alchemer.eu`)
* Fix ruby 3.2 build
* Fix ruby 2.7 build and compatibility with activesupport >= 7
* Switch CI from Travis to Github actions

## 7.1.1
* Add missing `subtype` parameter to `Campain` required at creation
* Fix use of deprecated Faraday error class (#110)

## 7.1.0
* Loosen dependencies on ActiveSupport and other gems to support Rails 6
* Minor fix to `SurveyGizmo::Configuration#region=` to raise proper error when region is invalid
* Update some development dependencies

## 7.0.0
* Makes configuration thread safe. When a new thread is created, the last configuration set through `SurveyGizmo.configure` will be used.

## 6.7.0
* Change timezone for EU servers to UTC (#103)

## 6.6.0
* Allow setting default locale for multi-language title (#101)

## 6.5.0
* Drop support for ruby 2.0; allow ActiveSupport 5.x

## 6.4.1
* remove unnecessary usage of `alias_method_chain` (#96)

## 6.4.0
* Allow passing of optional extra filters to `server_has_new_results_since?`

## 6.3.2
* Allow `Retriable` 3.0

## 6.3.1
* Deal with question_pipe quotes

## 6.3.0
* Deprecate `retry_attempts` and `retry_interval` configuration options
* Add ability to set the entire `Retriable` hash directly by configuring `retriable_params`

## 6.2.13
* max_elapsed_time of 1 hour for `Retriable`

## 6.2.12
* Bugfix: Don't allow option_ids of 0

## 6.2.11
* Bugfix: Mask CGI escaped (percent encoded) api tokens in logs

## 6.2.10
* Fix question pipe parsing when there's an integer without quotes instead of a quoted string (#87)

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
