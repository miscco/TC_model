/************************************************************************************************/
/*								Header file of a thalamic module								*/
/************************************************************************************************/
#pragma once
#include <cmath>
#include <vector>
#include <boost/random/mersenne_twister.hpp>
#include <boost/random/normal_distribution.hpp>
#include <boost/random/variate_generator.hpp>
#include "macros.h"
#include "Cortical_Column.h"
using std::vector;

class Cortical_Column;

/****************************************************************************************************/
/*										Typedefs for RNG											*/
/****************************************************************************************************/
typedef boost::mt11213b                    	ENG;    // Mersenne Twister
typedef boost::normal_distribution<double>	DIST;   // Normal Distribution
typedef boost::variate_generator<ENG,DIST> 	GEN;    // Variate generator
/****************************************************************************************************/
/*										 		end			 										*/
/****************************************************************************************************/


/****************************************************************************************************/
/*								Implementation of the thalamic module 								*/
/****************************************************************************************************/
class Thalamic_Column {
public:
	// Constructors
	Thalamic_Column(void)
	{set_RNG();}

	// Constructors
	Thalamic_Column(double* Par)
	: N_et 		(Par[0]),		N_er	(Par[1])
	{set_RNG();}

	// get the pointer to the cortical module
	void	get_Cortex	(Cortical_Column& C) {Cortex = &C;}

	// change the strength of input
	void	set_input	(double I) {input = I;}

	// get axonal flux
	double get_phi		(int N) const {_SWITCH((phi_t)); return var_phi_t;}

	// Initialize the RNGs
	void 	set_RNG		(void);

	// Firing rates
	double 	get_Qt		(int) const;
	double 	get_Qr		(int) const;

	// Synaptic currents
	double 	I_et		(int) const;
	double 	I_it		(int) const;
	double 	I_er		(int) const;
	double 	I_ir		(int) const;

	// Activation functions
	double  m_inf_T_t	(int) const;
	double  m_inf_T_r	(int) const;
	double  tau_m_T_t	(int) const;
	double  tau_m_T_r	(int) const;
	double  m_inf_h		(int) const;
	double  tau_m_h		(int) const;

	// Deactivation functions
	double  h_inf_T_t	(int) const;
	double  h_inf_T_r	(int) const;
	double  tau_h_T_t	(int) const;
	double  tau_h_T_r	(int) const;

	// Currents
	double 	I_L_t		(int) const;
	double 	I_L_r		(int) const;
	double 	I_LK_t		(int) const;
	double 	I_LK_r		(int) const;
	double 	I_T_t		(int) const;
	double 	I_T_r		(int) const;
	double 	I_h			(int) const;

	// Noise functions
	double 	noise_xRK 	(int) const;

	// ODE functions
	void 	set_RK		(int);
	void 	add_RK	 	(void);

	// Data storage
	friend void get_data (int, Cortical_Column&, Thalamic_Column&, _REPEAT(double*, 2));

private:
	// Population variables
	vector<double> 	Vt		= _INIT(E_L_t),		// TC membrane voltage
					Vr		= _INIT(E_L_r),		// RE membrane voltage
					Ca		= _INIT(Ca_0),		// Calcium concentration of TC population
					Phi_tt	= _INIT(0.0),		// PostSP from TC population to TC population
					Phi_tr	= _INIT(0.0),		// PostSP from TC population to RE population
					Phi_rt	= _INIT(0.0),		// PostSP from RE population to TC population
					Phi_rr	= _INIT(0.0),		// PostSP from RE population to RE population
					phi_t	= _INIT(0.0),		// axonal flux
					x_tt	= _INIT(0.0),		// derivative of Phi_tt
					x_tr	= _INIT(0.0),		// derivative of Phi_tr
					x_rt	= _INIT(0.0),		// derivative of Phi_rt
					x_rr	= _INIT(0.0),		// derivative of Phi_rr
					y_t		= _INIT(0.0),		// derivative of phi_t
					h_T_t	= _INIT(0.0),		// inactivation of T channel
					h_T_r	= _INIT(0.0),		// inactivation of T channel
					m_T_t	= _INIT(0.0),		// activation 	of T channel
					m_T_r	= _INIT(0.0),		// activation 	of T channel
					m_h		= _INIT(0.0),		// activation 	of h   channel
					m_h2	= _INIT(0.0),		// activation 	of h   channel bound with protein
					P_h		= _INIT(0.0);		// fraction of protein bound with calcium

	// Random number generators
	vector<GEN>		MTRands;

	// Container for noise
	vector<double>	Rand_vars;

	// Declaration and Initialization of parameters
	// Membrane time in ms
	const double 	tau_t 		= 30;
	const double 	tau_r 		= 30;

	// Maximum firing rate in ms^-1
	const double 	Qt_max		= 400.E-3;
	const double 	Qr_max		= 400.E-3;

	// Sigmoid threshold in mV
	const double 	theta_t		= -45;
	const double 	theta_r		= -45;

	// Sigmoid gain in mV
	const double 	sigma_t		= 9;
	const double 	sigma_r		= 9;

	// Scaling parameter for sigmoidal mapping (dimensionless)
	const double 	C1          = (3.14159265/sqrt(3));

	// PSP rise time in ms^-1
	const double 	gamma_e		= 70E-3;
	const double 	gamma_i		= 58.6E-3;

	/* axonal flux time constant */
	const double 	nu			= 60E-3;

	// Conductivities in mS/cm^-2
	// Leak current
	const double 	g_L_t  		= 0.02;
	const double 	g_L_r  		= 0.05;

	// Potassium leak current
	const double 	g_LK_t 		= 0.02;
	const double 	g_LK_r 		= 0.01;

	// T current
	const double	g_T_t		= 2.2;
	const double	g_T_r		= 2;

	/* h current */
	const double	g_h			= 0.07;

	// Connectivities (dimensionless)
	const double 	N_tr		= 2;
	const double 	N_rt		= 5.5;
	const double 	N_rr		= 5;
	const double 	N_et		= 10;
	const double 	N_er		= 10;

	// Reversal potentials in mV
	// synaptic
	const double 	E_AMPA  	= 0;
	const double 	E_GABA  	= -70;

	// Leak
	const double 	E_L_t 		= -70;
	const double 	E_L_r 		= -55;

	// Potassium
	const double 	E_K    		= -100;

	// I_T current
	const double 	E_Ca    	= 120;

	// I_h current
	const double 	E_h    		= -40;

	/* Calcium parameters */
	const double	alpha_Ca	= -50E-6;			// influx per spike in nmol
	const double	tau_Ca		= 5;				// calcium time constant in ms
	const double	Ca_0		= 2E-4;				// resting concentration

	/* I_h activation parameters */
	const double 	k1			= 2.5E7;
	const double 	k2			= 5E-4;
	const double 	k3			= 1E-1;
	const double 	k4			= 1E-3;
	const double 	n_P			= 4;
	const double 	g_inc		= 2;

	// Noise parameters in ms^-1
	const double 	mphi		= 0E-3;
	const double	dphi		= 2E-3;;
	double			input		= 0.0;

	/* Pointer to cortical column */
	Cortical_Column* Cortex;
};
/****************************************************************************************************/
/*										 		end			 										*/
/****************************************************************************************************/
