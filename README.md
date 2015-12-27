# ged
Ged project is a collection of tools useful for genealogical research:
1) search in a csv file  genealogical database: the database is a simple csv text file, with a row for each person
2) source image management and search: useful to browse digitalized record books, where images are ordered, and each image has a date and a type (i.e. birth, marriage, death)
3) interaction with a PhpGedView website via SOAP: used to crosscheck data between the csv database and a PhpGedView website


1 - search in a csv file

1.1 - format of the csv file
The base of this topic is a csv file containing the genealogical data (see file9_data.csv for an example).
Generally there is one row for each person, with fields for:
- id_file  (eg 'IDElenco'): a unique integer ID that identified the record
- nome     (eg 'Nome'): the main name (GIOVANNI GIACOMO MARIA CERES --> GIOVANNI)
- cogn     (eg 'Cognome'): the surname (GIOVANNI GIACOMO CERES --> CERES)
- nome_2   (eg 'Secondo nome'): all the secondary names (GIOVANNI GIACOMO CERES --> GIACOMO MARIA)
- pad_nome (eg 'Nomepadre'): name of the father (the surname is assumed to be the same as 'cogn' field)
- pad_nasc (eg 'Data di nascitaP'): birth date of the father
- mad_nome (eg 'NomeM'): name of the mother
- mad_cogn (eg 'CognomeM'): surname of the mother
- mad_nasc (eg 'Data di nascitaM'): birth date of the mother
- con_nome (eg 'Nomeconiuge'): name of the spouse
- con_cogn (eg 'Cognomeconiuge'): surname of the spouse
- nasc     (eg 'Data di nascita'): birth date in dd/mm/yyyy format
- nasc_luo (eg 'Paese'): place of birth
- nasc_Nr  (eg 'N-Atto nø'): number of the civil birth record (within the year)
- matr_civ (eg 'Data di matrimonio'): civil marriage date
- matr_rel (eg 'Data di matrimonio religioso'): religious marriage date
- matr     (eg 'Data di matrimonio principale'): main marriage date: civil marriage if present, otherwise religious one
- matr_Nr  (eg 'M-Atto nø'): number of the civil marriage record (within the year)
- mort     (eg 'Data di morte'): death date
- mort_luo (eg 'Paesedel decesso'): place of death
- mort_Nr  (eg 'Mo-Atto nø'): number of the civil death record (within the year)
- eta      (eg 'Mo-Eta'): age at death
- prof     (eg 'Mestiere'): occupation
- nasc_a   (eg 'Anno nascita'): year of birth
- nasc_m   (eg 'Mese nascita'): month of birth
- nasc_g   (eg 'Giorno nascita'): day of birth
- nasc_num (eg 'Data nascita'): decimal number representing the birth date (eg 17/04/1814 --> 1814.2930)
- matr_a   (eg 'Anno matrimonio'): year of marriage (based on matr field)
- matr_m   (eg 'Mese matrimonio'): month of marriage (based on matr field)
- matr_g   (eg 'Giorno matrimonio'): day of marriage (based on matr field)
- matr_num (eg 'Data matrimonio'): decimal number representing the marriage date (eg 17/04/1814 --> 1814.2930)
- mort_a   (eg 'Anno morte'): year of death
- mort_m   (eg 'Mese morte'): month of death
- mort_g   (eg 'Giorno morte'): day of death
- mort_num (eg 'Data morte'): decimal number representing the death date (eg 17/04/1814 --> 1814.2930)
- pad_prof (eg 'MestiereP'): occupation of father
- pad_eta  (eg 'EtaP'): age of father at birth
- mad_prof (eg 'MestiereM'): occupation of mother
- mad_eta  (eg 'EtaM'): age of mother at birth
- domic    (eg 'Domicilio'): domicile
- batt_chi (eg 'ChiesaBat'): church of baptism
- batt     (eg 'Data di battesimo'): baptism date
- con_orig (eg 'Paeseconiuge'): origin town of the spouse
- con_nasc (eg 'Data di nascitaconiuge'): birth date of the spouse
- con_eta  (eg 'Etaconiuge'): age of the spouse at marriage
- con_prof (eg 'Mestiereconiuge'): occupation of the spouse
- con_pad_nome (eg 'Nome padre coniuge'): name of the father of the spouse
- con_mad_cogn (eg 'Cognome mamma coniuge'): surname of the mother of the spouse
- con_mad_nome (eg 'Nome mamma coniuge'): name of the mother of the spouse
- matr_eta     (eg 'Eta'): age at marriage
- photo        (eg 'LinkFotografia'): name of the file with the photo, if present
- con_prec_M   (eg 'SposoPrecedente'): name of previous husband, in case of new marriage
- con_prec_F   (eg 'SposaPrecedente'): name of previous wife, in case of new marriage
- note         (eg 'Note'): note on the record. In case of multiple records referred to the same phisical person, the records must be linked by a note "VEDI ANCHE ID xxx" or  "VEDI ANCHE ID xxx AND yyy", where xxx and yyy are the id_file of the other records. This usually happens in case of a person that married more than once
- pad_pad      (eg 'NonnoPaterno'): name of the paternal grandfather
- mad_pad      (eg 'NonnoMaterno'): name of the paternal grandmother
- sep          (eg 'Data di sepoltura'): burial date
- emig         (eg 'Emigrazione'): emigration date

As indicated for the 'note' field, more than one id_file can be associated to one person. This could be because two different records were created without finding out that they referred to the same person, or because the person married more than once.

It is possible to use an Excel file as a worksheet, and then just save it as a comma separated value file, with a semicolon as a separator, and no "" to delimit strings.
In this case, to avoid problems when exchanging the file between more people, it is fundamental to force the text format for the date fields. This will preserve strange changes to the date when the file passes from an Italian configured pc to an English configured one (dd/mm/yyyy <--> mm/dd/yyyy). The reason of the additional, redundant nasc_a, nasc_m,nasc_g,... fields is to reinforce the correct date even in case of such a data change.
