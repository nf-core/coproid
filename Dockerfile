FROM continuumio/miniconda3

ENV env_file conda_env.yaml
ENV env_name coproid
ENV python_version 3.6

LABEL description="Docker image containing all requirements for coproID pipeline"
COPY ${env_file} /
RUN conda install python=${python_version}
RUN conda env create -f ${env_file} && conda clean -a
ENV PATH /opt/conda/envs/${env_name}/bin:$PATH
ENV PYTHONPATH /opt/conda/lib/python${python_version}/site-packages:$PYTHONPATH
ENV PYTHONPATH /opt/conda/envs/${env_name}/lib/python${python_version}/site-packages:$PYTHONPATH