# Variables
USER = radandri
ROOT = root
HOST = 127.0.0.1
PORT = 4242

# Cible par défaut pour se connecter en SSH
ssh:
	ssh -p $(PORT) $(USER)@$(HOST)

ssh-root:
	ssh -p $(PORT) $(ROOT)@$(HOST)

ssh-clean:
	ssh-keygen -R "[localhost]:4242"

copy_config_repo:
	scp -r -P $(PORT) config_file $(USER)@$(HOST):/home/$(USER)/

get_debian_iso_from_vm:
	scp -P $(PORT) $(USER)@$(HOST):/home/$(USER)/b2br/debian-preseeded.iso .

# copy_file:
# 	scp -P 4242 config_install.sh radandri@127.0.0.1:/home/radandri/

#crontab -e pour modifier a la main la frequence de temps dans le fichier

#crontab -l verifie que la modification a bien ete pris en compte
