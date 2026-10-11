FROM tomcat:9.0-jdk17-temurin

# Clear existing sample webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Deploy as ROOT application so it is accessible at the root URL (e.g., https://your-site.onrender.com/)
COPY SmartPlacementSystem.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
CMD ["catalina.sh", "run"]
