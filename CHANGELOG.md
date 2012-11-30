# Changelog

*0.3.0*

Removed RATING_RANGE constant.
The RATING_RANGE constant is very inflexible. Much better with a class method, since it allows for reusability, definint the range in a module that is pulled into several classes etc.

Instead this gem now includes several other config methods.