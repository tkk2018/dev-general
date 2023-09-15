# Repository pattern

### Repository and database table is not one to one relationship.
In short, the repository is a group of tables for creating a working dataset. Yes, some task may get unnecessary data, but everything has the trade off.

### Service and repository is not one to one relationship.
A service can inject as many as repositories to do the job.

### Can one repository calling another repository?
Should avoid. Because hard to detect and avoid circular dependency.

### Can one service calling another service?
Should avoid. Because hard to detect and avoid circular dependency.

### But you can have rule of thumb

Treat the third party related repositories and services as the highest level (module). Then the app's repositories can depends on their repositories and same go to the services.

## References:

* https://stackoverflow.com/a/30118760
* https://stackoverflow.com/a/74010049
* https://stackoverflow.com/a/60364987
* https://stackoverflow.com/a/1364702
* https://softwareengineering.stackexchange.com/a/372330
* https://softwareengineering.stackexchange.com/a/355178
