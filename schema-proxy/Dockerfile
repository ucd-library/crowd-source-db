FROM node:10

RUN mkdir /proxy

COPY package.json /proxy/
COPY package-lock.json /proxy/
RUN cd /proxy && npm install 

COPY lib /proxy/lib
COPY index.js /proxy/

CMD node proxy