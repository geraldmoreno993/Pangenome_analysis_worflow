#!/bin/bash                                                                     
#:Title: "Curso: Bioestadística en genómica microbiana"                                                      
#:Date: 01-10-2024                                                             
#:Author: "Gerald Moreno"                           
#:Version: 1.0                                                                 
#:Description : Análisis de datos genómicos bacterianos en Linuxm                             
#:Options: None 



#Ingresar a tu sesion de alumno
ssh -p 43931 alumno20@149.154.55.244
alumno20
sh ../Anaconda3-2024.06-1-Linux-x86_64.sh


#Subir genomas al servidor
##Salir de sesion y en tu pc ejecutar este comando
scp -P 43931 /media/gerald/DC604FBB604F9B62/sa_congreso/patric/fastas/*.fasta gerald@149.154.55.244:/home/warehouse/secuencias

#Bajar archivos del servidor
##Salir de sesion y en tu pc ejecutar este comando
scp -P 43931 -r alumno20@149.154.55.244:/home/warehouse/tunombre .

#Descargar cada muestra
# Archivo de entrada con los códigos de acceso (lista de las cepas con las que deseas trabajar
#Debes cambiar el nombre del inputfile por el archivo que te tocó
#No olvidar descargar herramienta datasets de NCBI de https://www.ncbi.nlm.nih.gov/datasets/docs/v2/download-and-install/

#Copia el archiov accessions.txt a la carpeta que creaste (con tu apellido) dentro de warehouse

#Datasets
#Bucle para descargar  múltiples secuencias (copiar y pegar todo desde imput a Descargas completas)
input_file="accessions.txt"
while IFS= read -r accession; do
    echo "Descargando $accession..."
    datasets download genome accession $accession --filename "${accession}.zip"
done < "$input_file"
echo "Descargas completas."

#Descomprimiendo
for archivo in *.zip; do
  nombre_carpeta="${archivo%.zip}"
  mkdir -p "$nombre_carpeta"
  unzip "$archivo" -d "$nombre_carpeta"
done


# Crear la carpeta 'fastas' si no existe
mkdir fastas

# Buscar y copiar todos los archivos .fna a la carpeta 'fastas'
find . -type f -name "*.fna" -exec cp {} fastas/ \;



#Entrando al ambiente de quast
conda activate quast

#Ejecutar quast sin  genoma representativo(referencia)
quast *.fna -o ./quast

#Con genoma de referencia o representativo (opcional)
#quast *.fna -r reference.fasta -o ./quast

#Cuando termine el procesamiento de Quast coloca exit en la terminal para salir de la sesion y ejecutar
scp -P 43931 -r alumno20@149.154.55.244:/home/warehouse/tunombre/fastas/quast .
#te va a pedir la contraseña de alumno
#Revisa que se encuentre la carpeta quast en tu computadora personal


#salir del ambiente
conda deactivate



###############
#####Prokka####
###############

#Ingreso al ambiente de Prokka
conda activate prokka

#Prokka solo capeta archivos.fasta, cambiando de extension a .fasta
for file in *.fna; do
    mv -- "$file" "${file%.fna}.fasta"
done

#Actualizar el blast
conda remove blast
conda install bioconda/label/cf201901::prokka

#Bucle para anotar multiples archivos fasta
for f in *.fasta; do 
  prokka --outdir "${f/.fasta}" --prefix "${f/.fasta}" --genus Staphylococcus --species aureus --strain "${f/.fasta}" "$f"; 
done


pwd

conda deactivate

#Preparar archivos .gff para roary
#ubicate donde estan tus fastas y sus respetivas carpetas de anotacion
mkdir roary
sudo cp **/*.gff ./roary


#Avanzar solamente hasta aquí
#-----------------------------------------------------------------------------------------------

##############
####Roary#####
##############


Conda activate roary
roary -e --mafft -p 8 *.gff


query_pan_genome


##Descargar archivos roary al dia siguiente
#Dentro de tu power shell establecerte en una carpeta específica de tu eleccción(tambien te puedes mover con cd)
scp -P 43931 -r alumnoX@149.154.55.244:/home/warehouse/gerald/roary .


#Snippy

conda activate snippy

#Descargar el genoma de referencia (trata de instalar el entrez antes o el snippy)
esearch -db nucleotide -query "CP000253" | efetch -format gbk > CP000253.gb
#o copia el que se encuentra en warehouse (comando cp)
cp /home/warehouse/genoma_referencia/NCTC8325.gbk .

for f in *.fna; do
    snippy --outdir "${f/.fna/}" --ref CP000253.gbk --ctgs "$f"
done


ls -d */

snippy-core --ref CP000253.gbk GCA_011059345.1_ASM1105934v1_genomic GCA_011059745.1_ASM1105974v1_genomic GCA_011060385.1_ASM1106038v1_genomic GCA_011061125.1_ASM1106112v1_genomic GCA_011059355.1_ASM1105935v1_genomic GCA_011059865.1_ASM1105986v1_genomic GCA_011060395.1_ASM1106039v1_genomic GCA_011061385.1_ASM1106138v1_genomic GCA_011059425.1_ASM1105942v1_genomic GCA_011059875.1_ASM1105987v1_genomic GCA_011060425.1_ASM1106042v1_genomic GCA_011059445.1_ASM1105944v1_genomic GCA_011059945.1_ASM1105994v1_genomic GCA_011060485.1_ASM1106048v1_genomic GCA_011059455.1_ASM1105945v1_genomic GCA_011060265.1_ASM1106026v1_genomic GCA_011060965.1_ASM1106096v1_genomic GCA_011059605.1_ASM1105960v1_genomic GCA_011060335.1_ASM1106033v1_genomic GCA_011060975.1_ASM1106097v1_genomic GCA_011059645.1_ASM1105964v1_genomic GCA_011060345.1_ASM1106034v1_genomic GCA_011060985.1_ASM1106098v1_genomic > report.txt

#Salir de la sesión con exit y ejecutar:
scp -P 43931 -r alumnoX@149.154.55.244:/home/warehouse/gerald/roary .


#VCF tools
conda activate vcftools
vcftools --vcf core.vcf --recode --maf 0.05 --out core_fil

#Eliminar las 3 primeras lineas del archivo 
#primer duplicamos el archivo para no dañarlo

cp core_fil.recode.vcf core_fil_copia.recode.vcf
nano core_fil.recode.vcf


sed '1,3d' core_fil_copia.recode.vcf > core_fil_copia2.recode.vcf
nano core_fil_copia2.recode.vcf



