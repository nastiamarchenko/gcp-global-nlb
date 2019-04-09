FROM python:3.5
RUN pip install selectors 
WORKDIR /data
COPY app.py /usr/local/bin/app.py
#COPY file.html /app/templates/file.html
#ENTRYPOINT ["python3.6"]
CMD ["python3.5","/usr/local/bin/app.py", "0.0.0.0","5000"]
