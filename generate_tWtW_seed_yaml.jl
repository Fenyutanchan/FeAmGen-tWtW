generate_tWtW_seed_yaml(nloop::Integer) =   """
# input file for calculation details
# model related information

# model name
model_name: "sm_tbW"

# use unitary_gauge for internal vector boson
unitary_gauge: true

# content of "quark-parton", the "parton" will also contain gluon. Only for seed program.
#const partons = Array{String,1}( [ "g", "u", "d", "ubar", "dbar", "s", "c", "b", "sbar", "cbar", "bbar" ] )   
# for single top @ NNLO
#const partons = Array{String,1}( [ "g", "u", "d", "ubar", "dbar", "b", "bbar" ] )   
# for Higgs+Jet @ NLO
partons: [ "g", "u", "ubar", "d", "dbar", "b", "bbar" ] 

# only for seed program
AllowLeptonNumberViolation: false
AllowQuarkGenerationViolation: false

# process information
DropTadpole: true              # drop tadpole?
DropWFcorrection: true         # drop WFcorrection?

# number of loops
n_loop: $(nloop)
# order of QCD counter-term vertices
QCDCT_order: 0   

# order of QCD coupling gs in the amplitude
Amp_QCD_order: $(2 * nloop) 
# order of QED coupling ee in the amplitude
Amp_QED_order: 0  
# order of special coupling in the amplitude
Amp_SPC_order: 2  

# min ep power in the amplitude
Amp_Min_Ep_Xpt: $(-2 * nloop)
# max ep power in the amplitude
Amp_Max_Ep_Xpt: 0

# incoming and outgoing information
incoming: [ "Wplus", "t" ]          # incoming particles
outgoing: [ "Wplus", "t" ]          # outgoing particles 

# Symmetry configuration
symmetry: 
  - [ K3, K1 ] # K3=>K1
  - [ K4, K2 ] # K4=>K2
"""
