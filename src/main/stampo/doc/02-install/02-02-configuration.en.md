## Configuration

collapp can run as a standalone application or inside a servlet 3.0+ container.

### Self contained

As a standalone application, see the `bin/collapp.sh`, `bin/collapp.bat` or `bin/windows-service/collapp.xml` scripts and configure them. It will launch the app using a self contained [jetty](https://www.eclipse.org/jetty/) server.

As a default, collapp launch in dev mode, so check in the scripts that the spring.profiles.active property is set to **prod**.

### Servlet container

You can deploy in any servlet 3.0 container. You will need to set the following
property to the JVM (see the scripts bin/collapp.sh / bin/collapp.bat):

 - datasource.dialect=HSQLDB | MYSQL | PGSQL
 - datasource.url= for example: jdbc:hsqldb:mem:collapp | jdbc:mysql://localhost:3306/collapp?useUnicode=true&characterEncoding=utf-8 | jdbc:postgresql://localhost:5432/collapp
 - datasource.username=[username]
 - datasource.password=[pwd]
 - spring.profiles.active= dev | prod

Or

You can define them in an external file (like the bundled sample-conf.properties) and define the following property:

 - collapp.config.location=file:/your/file/location.properties
