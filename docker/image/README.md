# Note  
A file called `Qt-6.10.0.tar` is required to build the image, it contains the compiled code of Qt-6.10.0 specifically build on the Jetson. If you are trying to build this image, and need this file either create it yourself, or contact Raleigh Slack.  

## Building
```sudo docker build -t <your-tag> .```  
From there you can use the docker compose in the /docker folder to run your image, making sure to edit the image parameter of the docker compose. It will start the HMI code in the container.
