FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    sudo wget gdebi-core \
    libssl-dev libcurl4-openssl-dev libxml2-dev \
    r-base r-base-dev \
    pandoc libxt6 libx11-dev \
    git 

# Install RStudio Server
RUN wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-2023.12.0-369-amd64.deb && \
    gdebi -n rstudio-server-2023.12.0-369-amd64.deb && \
    rm rstudio-server-2023.12.0-369-amd64.deb

# Create rstudio user
RUN useradd -m rstudio && echo "rstudio:rstudio" | chpasswd && adduser rstudio sudo

# Expose RStudio port
EXPOSE 8787

# Set working dir
WORKDIR /home/rstudio

# Copy in project
COPY . /home/rstudio/my-wgcna-project
WORKDIR /home/rstudio/my-wgcna-project

# Set permissions
RUN chown -R rstudio:rstudio /home/rstudio/my-wgcna-project

# Switch to rstudio user and install renv/WGCNA
USER rstudio
RUN R -e "install.packages('renv', repos = 'https://cloud.r-project.org')"

CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize=0"]
