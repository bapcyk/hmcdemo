
Classes
=======

::HMC6343Protocol
-----------------

Variables
~~~~~~~~~

- protected ::HMC6343Protocol::this

Methods
~~~~~~~

*::HMC6343Protocol::get*: **cmd what**

::

	Returns protocol info (what) about command cmd. What is:
	  -def - definition of command (Tcl commands list to be execute for request)
	  -resplen - length of response in bytes
	  -respfmt - format of response
	  -all - as fields as list


*::HMC6343Protocol::unpack*: **cmd buf**

::

	Returns unpacked (as list) values from buf for cmd


*::HMC6343Protocol::commands*: **no args.**

::

	Returns known commands names


*::HMC6343Protocol::constructor*: **defs**

::

	Creates object.
	  - defs is the list of CMD RESPONSE_LEN RESPONSE_FMT { Serial commands }...
	  - RESPONSE_FMT is like in binary command


::Uicells (*extends ::DataListener*)
------------------------------------

Variables
~~~~~~~~~

- protected ::Uicells::this
- protected ::Uicells::FMT
- public ::DataListener::all
- public ::DataListener::datatypes

Methods
~~~~~~~

*::Uicells::line*: **{char =}**

::

	Adds delimiter line filled with char symbol


*::Uicells::clear*: **<undefined>**

::

	Clears content of the grid


*::DataListener::listened*: **no args.**

::

	Is listening now?


*::DataListener::event*: **ev src args**

::

	generate event (call callback) for this listener.
	ev is ListenEvent object, src is the source of event.
	ev is one of run|stop|data|on|off|add|del:
	  run - before first packet sent
	  stop - after last packet sent
	  data - packet is received
	  on - enable listening
	  off - disable listening
	  add - connect with some data provider
	  del - disconnect from some data provider


*::DataListener::listen*: **what**

::

	listen -on -- turn-on listening
	listen -off -- turn-off listening


::PhysValues (*extends ::DataListener ::DataProvider*)
------------------------------------------------------

Variables
~~~~~~~~~

- protected ::PhysValues::this
- protected ::PhysValues::COLUMNS
- public ::PhysValues::corrg
- protected ::PhysValues::UNITS
- public ::DataListener::all
- public ::DataListener::datatypes
- public ::DataProvider::datatype
- public ::DataProvider::all

Methods
~~~~~~~

*::PhysValues::reset*: **no args.**

::

	Reset internal state


*::DataListener::listened*: **no args.**

::

	Is listening now?


*::DataListener::event*: **ev src args**

::

	generate event (call callback) for this listener.
	ev is ListenEvent object, src is the source of event.
	ev is one of run|stop|data|on|off|add|del:
	  run - before first packet sent
	  stop - after last packet sent
	  data - packet is received
	  on - enable listening
	  off - disable listening
	  add - connect with some data provider
	  del - disconnect from some data provider


*::DataListener::listen*: **what**

::

	listen -on -- turn-on listening
	listen -off -- turn-off listening


*::DataProvider::get_listeners*: **no args.**

::

	Returns names of all listeners


*::DataProvider::del_listener*: **listener {stop 1}**

::

	Deletes listener, sends before stop event if needed


*::DataProvider::del_all_listeners*: **{stop 1}**

::

	Deletes all listeners, send stop event before, if needed


*::DataProvider::notify_all*: **ev args**

::

	Notify all listeners with event ev and some args


*::DataProvider::number*: **no args.**

::

	Returns number of listeners


*::DataProvider::add_listener*: **listener**

::

	Add some listener


::BaseFilter (*extends ::DataListener ::DataProvider*)
------------------------------------------------------

Variables
~~~~~~~~~

- protected ::BaseFilter::this
- protected ::BaseFilter::COLUMNS
- protected ::BaseFilter::UNITS
- public ::DataListener::all
- public ::DataListener::datatypes
- public ::DataProvider::datatype
- public ::DataProvider::all

Methods
~~~~~~~

*::BaseFilter::chconfigure*: **args**

::

	Configure channels' filters:
	  -ord int|{int0 int1...} -- order of filter
	  -f1 double|{double0 double1...} -- cut freq 1
	  -f2 double|{double0 double1...} -- cut freq 2
	  -win bool|{bool0 bool1...} -- need Blackman window?
	  -norm bool|{bool0 bool1...} -- need normalization of coefficients?
	  -fs double|{double0 double1...} -- sampling freq (if omitted, sensor get_freq is used)
	
	Positional args are indexes of channels to be filtered or 'all'. Ex:
	
	  chconfigure 0 1 3 -f1 {10 20 30} -ord {15 20 25}
	
	All freqs are in Hz. Sampling freq is obtained from sensor when onrun is called.
	Without args, returns last chconfigure string


*::BaseFilter::get_cfir*: **i**

::

	Returns core FIR (on C in DLL) object


*::BaseFilter::reset*: **no args.**

::

	Reset internal state


*::DataListener::listened*: **no args.**

::

	Is listening now?


*::DataListener::event*: **ev src args**

::

	generate event (call callback) for this listener.
	ev is ListenEvent object, src is the source of event.
	ev is one of run|stop|data|on|off|add|del:
	  run - before first packet sent
	  stop - after last packet sent
	  data - packet is received
	  on - enable listening
	  off - disable listening
	  add - connect with some data provider
	  del - disconnect from some data provider


*::DataListener::listen*: **what**

::

	listen -on -- turn-on listening
	listen -off -- turn-off listening


*::DataProvider::get_listeners*: **no args.**

::

	Returns names of all listeners


*::DataProvider::del_listener*: **listener {stop 1}**

::

	Deletes listener, sends before stop event if needed


*::DataProvider::del_all_listeners*: **{stop 1}**

::

	Deletes all listeners, send stop event before, if needed


*::DataProvider::notify_all*: **ev args**

::

	Notify all listeners with event ev and some args


*::DataProvider::number*: **no args.**

::

	Returns number of listeners


*::DataProvider::add_listener*: **listener**

::

	Add some listener


::LPFilter (*extends ::DataListener ::DataProvider*)
----------------------------------------------------

Variables
~~~~~~~~~

- public ::LPFilter::dt
- protected ::LPFilter::this
- public ::LPFilter::rc
- protected ::LPFilter::COLUMNS
- protected ::LPFilter::UNITS
- public ::DataListener::all
- public ::DataListener::datatypes
- public ::DataProvider::datatype
- public ::DataProvider::all

Methods
~~~~~~~

*::LPFilter::get_coeff*: **args**

::

	Returns coefficient


*::LPFilter::reset*: **no args.**

::

	Reset internal state


*::DataListener::listened*: **no args.**

::

	Is listening now?


*::DataListener::event*: **ev src args**

::

	generate event (call callback) for this listener.
	ev is ListenEvent object, src is the source of event.
	ev is one of run|stop|data|on|off|add|del:
	  run - before first packet sent
	  stop - after last packet sent
	  data - packet is received
	  on - enable listening
	  off - disable listening
	  add - connect with some data provider
	  del - disconnect from some data provider


*::DataListener::listen*: **what**

::

	listen -on -- turn-on listening
	listen -off -- turn-off listening


*::DataProvider::get_listeners*: **no args.**

::

	Returns names of all listeners


*::DataProvider::del_listener*: **listener {stop 1}**

::

	Deletes listener, sends before stop event if needed


*::DataProvider::del_all_listeners*: **{stop 1}**

::

	Deletes all listeners, send stop event before, if needed


*::DataProvider::notify_all*: **ev args**

::

	Notify all listeners with event ev and some args


*::DataProvider::number*: **no args.**

::

	Returns number of listeners


*::DataProvider::add_listener*: **listener**

::

	Add some listener


::Ui3d (*extends ::DataListener*)
---------------------------------

Variables
~~~~~~~~~

- protected ::Ui3d::this
- public ::DataListener::all
- public ::DataListener::datatypes

Methods
~~~~~~~

*::DataListener::listened*: **no args.**

::

	Is listening now?


*::DataListener::event*: **ev src args**

::

	generate event (call callback) for this listener.
	ev is ListenEvent object, src is the source of event.
	ev is one of run|stop|data|on|off|add|del:
	  run - before first packet sent
	  stop - after last packet sent
	  data - packet is received
	  on - enable listening
	  off - disable listening
	  add - connect with some data provider
	  del - disconnect from some data provider


*::DataListener::listen*: **what**

::

	listen -on -- turn-on listening
	listen -off -- turn-off listening


::SIntr (*extends ::DataListener ::DataProvider*)
-------------------------------------------------

Variables
~~~~~~~~~

- public ::SIntr::h
- protected ::SIntr::this
- public ::DataListener::all
- public ::DataListener::datatypes
- public ::DataProvider::datatype
- public ::DataProvider::all

Methods
~~~~~~~

*::SIntr::get_intr*: **i**

::

	Returns 1 of 3 integrators


*::SIntr::reset*: **no args.**

::

	Reset internal state


*::DataListener::listened*: **no args.**

::

	Is listening now?


*::DataListener::event*: **ev src args**

::

	generate event (call callback) for this listener.
	ev is ListenEvent object, src is the source of event.
	ev is one of run|stop|data|on|off|add|del:
	  run - before first packet sent
	  stop - after last packet sent
	  data - packet is received
	  on - enable listening
	  off - disable listening
	  add - connect with some data provider
	  del - disconnect from some data provider


*::DataListener::listen*: **what**

::

	listen -on -- turn-on listening
	listen -off -- turn-off listening


*::DataProvider::get_listeners*: **no args.**

::

	Returns names of all listeners


*::DataProvider::del_listener*: **listener {stop 1}**

::

	Deletes listener, sends before stop event if needed


*::DataProvider::del_all_listeners*: **{stop 1}**

::

	Deletes all listeners, send stop event before, if needed


*::DataProvider::notify_all*: **ev args**

::

	Notify all listeners with event ev and some args


*::DataProvider::number*: **no args.**

::

	Returns number of listeners


*::DataProvider::add_listener*: **listener**

::

	Add some listener


::DataProvider
--------------

Variables
~~~~~~~~~

- public ::DataProvider::datatype
- protected ::DataProvider::this
- public ::DataProvider::all

Methods
~~~~~~~

*::DataProvider::get_listeners*: **no args.**

::

	Returns names of all listeners


*::DataProvider::del_listener*: **listener {stop 1}**

::

	Deletes listener, sends before stop event if needed


*::DataProvider::del_all_listeners*: **{stop 1}**

::

	Deletes all listeners, send stop event before, if needed


*::DataProvider::notify_all*: **ev args**

::

	Notify all listeners with event ev and some args


*::DataProvider::number*: **no args.**

::

	Returns number of listeners


*::DataProvider::add_listener*: **listener**

::

	Add some listener


::HPFilter (*extends ::DataListener ::DataProvider*)
----------------------------------------------------

Variables
~~~~~~~~~

- public ::HPFilter::dt
- protected ::HPFilter::this
- public ::HPFilter::rc
- protected ::HPFilter::COLUMNS
- protected ::HPFilter::UNITS
- public ::DataListener::all
- public ::DataListener::datatypes
- public ::DataProvider::datatype
- public ::DataProvider::all

Methods
~~~~~~~

*::HPFilter::get_coeff*: **args**

::

	Returns coefficient


*::HPFilter::reset*: **no args.**

::

	Reset internal state


*::DataListener::listened*: **no args.**

::

	Is listening now?


*::DataListener::event*: **ev src args**

::

	generate event (call callback) for this listener.
	ev is ListenEvent object, src is the source of event.
	ev is one of run|stop|data|on|off|add|del:
	  run - before first packet sent
	  stop - after last packet sent
	  data - packet is received
	  on - enable listening
	  off - disable listening
	  add - connect with some data provider
	  del - disconnect from some data provider


*::DataListener::listen*: **what**

::

	listen -on -- turn-on listening
	listen -off -- turn-off listening


*::DataProvider::get_listeners*: **no args.**

::

	Returns names of all listeners


*::DataProvider::del_listener*: **listener {stop 1}**

::

	Deletes listener, sends before stop event if needed


*::DataProvider::del_all_listeners*: **{stop 1}**

::

	Deletes all listeners, send stop event before, if needed


*::DataProvider::notify_all*: **ev args**

::

	Notify all listeners with event ev and some args


*::DataProvider::number*: **no args.**

::

	Returns number of listeners


*::DataProvider::add_listener*: **listener**

::

	Add some listener


::HMC6343EEPROM
---------------

Variables
~~~~~~~~~

- protected ::HMC6343EEPROM::this

Methods
~~~~~~~

*::HMC6343EEPROM::read*: **addr**

::

	Reads data from EEPROM cell.
	addr may be integer (0x00|0, or cell name). When addr is integer,
	reads one address, when is cell name, then reads all addresses of
	this named entry


*::HMC6343EEPROM::constructor*: **defs**

::

	Creates object. defs - definition of EEPROM cells


*::HMC6343EEPROM::edit*: **no args.**

::

	Call UI editor of EEPROM cells


*::HMC6343EEPROM::save*: **fname**

::

	Saves EEPROM content to CSV file fname


*::HMC6343EEPROM::get*: **name what**

::

	Returns info about named cell.
	what is one of the:
	  -addr - start address
	  -len - number of bytes from this address
	  -fact - factory default | --
	  -fmt - format (like binary scan)
	  -valid - validator
	  -descr - description


*::HMC6343EEPROM::load*: **fname {reset {}}**

::

	Loads EEPROM content from CSV file, early saved by save method.
	If reset is "-reset", then reset MCU after loading (to apply
	EEPROM setup)


*::HMC6343EEPROM::cells*: **no args.**

::

	Returns cells names


*::HMC6343EEPROM::write*: **addr value**

::

	Writes data into cell.
	addr is integer or cell name. When is the integer, write
	only into this address, when is the cell name, writes
	into several addresses (of this named cell)


::Hpfir (*extends ::BaseFilter ::DataListener ::DataProvider*)
--------------------------------------------------------------

Variables
~~~~~~~~~

- protected ::Hpfir::this
- protected ::BaseFilter::COLUMNS
- protected ::BaseFilter::UNITS
- public ::DataListener::all
- public ::DataListener::datatypes
- public ::DataProvider::datatype
- public ::DataProvider::all

Methods
~~~~~~~

*::Hpfir::reset*: **no args.**

::

	Reset internal state


*::BaseFilter::chconfigure*: **args**

::

	Configure channels' filters:
	  -ord int|{int0 int1...} -- order of filter
	  -f1 double|{double0 double1...} -- cut freq 1
	  -f2 double|{double0 double1...} -- cut freq 2
	  -win bool|{bool0 bool1...} -- need Blackman window?
	  -norm bool|{bool0 bool1...} -- need normalization of coefficients?
	  -fs double|{double0 double1...} -- sampling freq (if omitted, sensor get_freq is used)
	
	Positional args are indexes of channels to be filtered or 'all'. Ex:
	
	  chconfigure 0 1 3 -f1 {10 20 30} -ord {15 20 25}
	
	All freqs are in Hz. Sampling freq is obtained from sensor when onrun is called.
	Without args, returns last chconfigure string


*::BaseFilter::get_cfir*: **i**

::

	Returns core FIR (on C in DLL) object


*::BaseFilter::reset*: **no args.**

::

	Reset internal state


*::DataListener::listened*: **no args.**

::

	Is listening now?


*::DataListener::event*: **ev src args**

::

	generate event (call callback) for this listener.
	ev is ListenEvent object, src is the source of event.
	ev is one of run|stop|data|on|off|add|del:
	  run - before first packet sent
	  stop - after last packet sent
	  data - packet is received
	  on - enable listening
	  off - disable listening
	  add - connect with some data provider
	  del - disconnect from some data provider


*::DataListener::listen*: **what**

::

	listen -on -- turn-on listening
	listen -off -- turn-off listening


*::DataProvider::get_listeners*: **no args.**

::

	Returns names of all listeners


*::DataProvider::del_listener*: **listener {stop 1}**

::

	Deletes listener, sends before stop event if needed


*::DataProvider::del_all_listeners*: **{stop 1}**

::

	Deletes all listeners, send stop event before, if needed


*::DataProvider::notify_all*: **ev args**

::

	Notify all listeners with event ev and some args


*::DataProvider::number*: **no args.**

::

	Returns number of listeners


*::DataProvider::add_listener*: **listener**

::

	Add some listener


::DSIntr (*extends ::DataListener ::DataProvider*)
--------------------------------------------------

Variables
~~~~~~~~~

- protected ::DSIntr::this
- protected ::DSIntr::COLUMNS
- public ::DSIntr::fon
- protected ::DSIntr::UNITS
- public ::DataListener::all
- public ::DataListener::datatypes
- public ::DataProvider::datatype
- public ::DataProvider::all

Methods
~~~~~~~

*::DSIntr::links*: **{mode {}}**

::

	Describes links in column mode (mode is "-col"), string mode otherwise.


*::DSIntr::set_flt*: **iflt flt**

::

	Replaces existent filter object in iflt position with another one.
	Flt may be any filter, but High-Pass are preferred by algorithm.
	After replacing returns old.


*::DSIntr::reset*: **no args.**

::

	Reset internal state


*::DSIntr::get_flt*: **i**

::

	Returns filter by cascade number i


*::DSIntr::constructor*: **no args.**

::

	filter - need filtering or only integrate


*::DSIntr::prepare_flt*: **iflt flt**

::

	Configures some filter object (flt) with standard options for this algorithm.
	iflt is needed to specified position (in common way options should depends on
	position: input filter or, for ex., output filter cascade)


*::DSIntr::get_intr*: **i**

::

	Returns integrator by cascade number i:
	  channel0 -> .. -> 0 -> .. -> 3
	  channel1 -> .. -> 1 -> .. -> 4
	  channel2 -> .. -> 2 -> .. -> 5


*::DSIntr::link_all*: **no args.**

::

	Links all cascades with filtering usage (filter=1), otherwise
	without filters.


*::DataListener::listened*: **no args.**

::

	Is listening now?


*::DataListener::event*: **ev src args**

::

	generate event (call callback) for this listener.
	ev is ListenEvent object, src is the source of event.
	ev is one of run|stop|data|on|off|add|del:
	  run - before first packet sent
	  stop - after last packet sent
	  data - packet is received
	  on - enable listening
	  off - disable listening
	  add - connect with some data provider
	  del - disconnect from some data provider


*::DataListener::listen*: **what**

::

	listen -on -- turn-on listening
	listen -off -- turn-off listening


*::DataProvider::get_listeners*: **no args.**

::

	Returns names of all listeners


*::DataProvider::del_listener*: **listener {stop 1}**

::

	Deletes listener, sends before stop event if needed


*::DataProvider::del_all_listeners*: **{stop 1}**

::

	Deletes all listeners, send stop event before, if needed


*::DataProvider::notify_all*: **ev args**

::

	Notify all listeners with event ev and some args


*::DataProvider::number*: **no args.**

::

	Returns number of listeners


*::DataProvider::add_listener*: **listener**

::

	Add some listener


::DebugListener (*extends ::ProxyListener ::DataListener ::DataProvider*)
-------------------------------------------------------------------------

Variables
~~~~~~~~~

- protected ::DebugListener::this
- public ::DebugListener::fixed_cu
- public ::ProxyListener::origin
- public ::ProxyListener::ondelproc
- public ::ProxyListener::onaddproc
- public ::ProxyListener::onrunproc
- public ::ProxyListener::ondataproc
- public ::ProxyListener::onstopproc
- public ::DataListener::all
- public ::DataListener::datatypes
- public ::DataProvider::datatype
- public ::DataProvider::all

Methods
~~~~~~~

*::DebugListener::constructor*: **{f stdout} {fmt {}}**

::

	f - output channel id. fmt - format string, default is the
	"*DEBUG_${THIS} ${EVENT}*: $ARGS"


*::DataListener::listened*: **no args.**

::

	Is listening now?


*::DataListener::event*: **ev src args**

::

	generate event (call callback) for this listener.
	ev is ListenEvent object, src is the source of event.
	ev is one of run|stop|data|on|off|add|del:
	  run - before first packet sent
	  stop - after last packet sent
	  data - packet is received
	  on - enable listening
	  off - disable listening
	  add - connect with some data provider
	  del - disconnect from some data provider


*::DataListener::listen*: **what**

::

	listen -on -- turn-on listening
	listen -off -- turn-off listening


*::DataProvider::get_listeners*: **no args.**

::

	Returns names of all listeners


*::DataProvider::del_listener*: **listener {stop 1}**

::

	Deletes listener, sends before stop event if needed


*::DataProvider::del_all_listeners*: **{stop 1}**

::

	Deletes all listeners, send stop event before, if needed


*::DataProvider::notify_all*: **ev args**

::

	Notify all listeners with event ev and some args


*::DataProvider::number*: **no args.**

::

	Returns number of listeners


*::DataProvider::add_listener*: **listener**

::

	Add some listener


::ProxyListener (*extends ::DataListener ::DataProvider*)
---------------------------------------------------------

Variables
~~~~~~~~~

- public ::ProxyListener::origin
- protected ::ProxyListener::this
- public ::ProxyListener::ondelproc
- public ::ProxyListener::onaddproc
- public ::ProxyListener::onrunproc
- public ::ProxyListener::ondataproc
- public ::ProxyListener::onstopproc
- public ::DataListener::all
- public ::DataListener::datatypes
- public ::DataProvider::datatype
- public ::DataProvider::all

Methods
~~~~~~~

*::DataListener::listened*: **no args.**

::

	Is listening now?


*::DataListener::event*: **ev src args**

::

	generate event (call callback) for this listener.
	ev is ListenEvent object, src is the source of event.
	ev is one of run|stop|data|on|off|add|del:
	  run - before first packet sent
	  stop - after last packet sent
	  data - packet is received
	  on - enable listening
	  off - disable listening
	  add - connect with some data provider
	  del - disconnect from some data provider


*::DataListener::listen*: **what**

::

	listen -on -- turn-on listening
	listen -off -- turn-off listening


*::DataProvider::get_listeners*: **no args.**

::

	Returns names of all listeners


*::DataProvider::del_listener*: **listener {stop 1}**

::

	Deletes listener, sends before stop event if needed


*::DataProvider::del_all_listeners*: **{stop 1}**

::

	Deletes all listeners, send stop event before, if needed


*::DataProvider::notify_all*: **ev args**

::

	Notify all listeners with event ev and some args


*::DataProvider::number*: **no args.**

::

	Returns number of listeners


*::DataProvider::add_listener*: **listener**

::

	Add some listener


::CIntr (*extends ::DataListener ::DataProvider*)
-------------------------------------------------

Variables
~~~~~~~~~

- protected ::CIntr::this
- public ::CIntr::a
- protected ::CIntr::COLUMNS
- protected ::CIntr::UNITS
- public ::DataListener::all
- public ::DataListener::datatypes
- public ::DataProvider::datatype
- public ::DataProvider::all

Methods
~~~~~~~

*::CIntr::get_coeff*: **args**

::

	Returns coefficient


*::CIntr::reset*: **no args.**

::

	Reset internal state


*::DataListener::listened*: **no args.**

::

	Is listening now?


*::DataListener::event*: **ev src args**

::

	generate event (call callback) for this listener.
	ev is ListenEvent object, src is the source of event.
	ev is one of run|stop|data|on|off|add|del:
	  run - before first packet sent
	  stop - after last packet sent
	  data - packet is received
	  on - enable listening
	  off - disable listening
	  add - connect with some data provider
	  del - disconnect from some data provider


*::DataListener::listen*: **what**

::

	listen -on -- turn-on listening
	listen -off -- turn-off listening


*::DataProvider::get_listeners*: **no args.**

::

	Returns names of all listeners


*::DataProvider::del_listener*: **listener {stop 1}**

::

	Deletes listener, sends before stop event if needed


*::DataProvider::del_all_listeners*: **{stop 1}**

::

	Deletes all listeners, send stop event before, if needed


*::DataProvider::notify_all*: **ev args**

::

	Notify all listeners with event ev and some args


*::DataProvider::number*: **no args.**

::

	Returns number of listeners


*::DataProvider::add_listener*: **listener**

::

	Add some listener


::DataListener
--------------

Variables
~~~~~~~~~

- protected ::DataListener::this
- public ::DataListener::all
- public ::DataListener::datatypes

Methods
~~~~~~~

*::DataListener::listened*: **no args.**

::

	Is listening now?


*::DataListener::event*: **ev src args**

::

	generate event (call callback) for this listener.
	ev is ListenEvent object, src is the source of event.
	ev is one of run|stop|data|on|off|add|del:
	  run - before first packet sent
	  stop - after last packet sent
	  data - packet is received
	  on - enable listening
	  off - disable listening
	  add - connect with some data provider
	  del - disconnect from some data provider


*::DataListener::listen*: **what**

::

	listen -on -- turn-on listening
	listen -off -- turn-off listening


::Saver (*extends ::DataListener*)
----------------------------------

Variables
~~~~~~~~~

- protected ::Saver::this
- public ::Saver::name
- public ::Saver::fpatt
- public ::Saver::dir
- public ::DataListener::all
- public ::DataListener::datatypes

Methods
~~~~~~~

*::DataListener::listened*: **no args.**

::

	Is listening now?


*::DataListener::event*: **ev src args**

::

	generate event (call callback) for this listener.
	ev is ListenEvent object, src is the source of event.
	ev is one of run|stop|data|on|off|add|del:
	  run - before first packet sent
	  stop - after last packet sent
	  data - packet is received
	  on - enable listening
	  off - disable listening
	  add - connect with some data provider
	  del - disconnect from some data provider


*::DataListener::listen*: **what**

::

	listen -on -- turn-on listening
	listen -off -- turn-off listening


::HMC6343 (*extends ::DataProvider*)
------------------------------------

Variables
~~~~~~~~~

- protected ::HMC6343::this
- protected ::HMC6343::COLUMNS
- protected ::HMC6343::UNITS
- public ::DataProvider::datatype
- public ::DataProvider::all

Methods
~~~~~~~

*::HMC6343::set_hfilter*: **{value 1}**

::

	Turn-on filtering with this value (1..15: order of the filter);
	0 value turn-off filtering


*::HMC6343::request*: **args**

::

	One request to sensor device:
	  request REEPROM ADDR 0x00;
	0x00 but not 0 !
	Should be call serial listen -on before!


*::HMC6343::enter_mode*: **mode**

::

	Enter to mode, mode is {CALIBR|RUN|STANDBY|SLEEP}


*::HMC6343::set_orient*: **orient**

::

	Set orientation of the sensor chip package. orient may be:
	{LEVEL or YXZ, UPRIGHT_EDGE or UE or XZY, UPRIGHT_FRONT or UF or -ZYX}


*::HMC6343::exit_mode*: **mode**

::

	Exit from mode, mode is {CALIBR|SLEEP}


*::HMC6343::reset_mcu*: **no args.**

::

	Reset sensor MCU


*::HMC6343::poll*: **args**

::

	Polling, possible in loop. Has options:
	  -loop - infinite loop of polling
	  -loop N - loop N times polling
	  -loop stop|cancel - stop looping


*::HMC6343::set_freq*: **{freq 5}**

::

	Set sampling frequency: 1, 5, 10


*::HMC6343::get_op_mode1*: **{form -dec}**

::

	Get OPMODE1 register. Forms are form of output: -hex/-dec/-bin/-txt
	  -hex - like 0x0F
	  -dec - like 15
	  -bin - like 0b00001111
	  -txt - text decription


*::HMC6343::get_op_mode2*: **{form -dec}**

::

	Get OPMODE2 register. Forms are form of output: -hex/-dec/-bin/-txt
	  -hex - like 0x0F
	  -dec - like 15
	  -bin - like 0b00001111
	  -txt - text decription


*::HMC6343::get_freq*: **no args.**

::

	Get current sampling frequency


*::DataProvider::get_listeners*: **no args.**

::

	Returns names of all listeners


*::DataProvider::del_listener*: **listener {stop 1}**

::

	Deletes listener, sends before stop event if needed


*::DataProvider::del_all_listeners*: **{stop 1}**

::

	Deletes all listeners, send stop event before, if needed


*::DataProvider::notify_all*: **ev args**

::

	Notify all listeners with event ev and some args


*::DataProvider::number*: **no args.**

::

	Returns number of listeners


*::DataProvider::add_listener*: **listener**

::

	Add some listener


::Uiplot (*extends ::DataListener*)
-----------------------------------

Variables
~~~~~~~~~

- protected ::Uiplot::z_color
- protected ::Uiplot::this
- protected ::Uiplot::y_center
- protected ::Uiplot::cw
- protected ::Uiplot::NT
- protected ::Uiplot::ch
- protected ::Uiplot::x_end
- protected ::Uiplot::vertpad
- protected ::Uiplot::y_end
- protected ::Uiplot::pw
- protected ::Uiplot::z_end
- protected ::Uiplot::x_center
- protected ::Uiplot::ph
- protected ::Uiplot::horizpad
- protected ::Uiplot::bw
- protected ::Uiplot::z_center
- protected ::Uiplot::title
- protected ::Uiplot::x_color
- protected ::Uiplot::y_color
- public ::DataListener::all
- public ::DataListener::datatypes

Methods
~~~~~~~

*::Uiplot::set_intr*: **intrname**

::

	Changes used integrator. intrname is {dsintr|cintr}


*::DataListener::listened*: **no args.**

::

	Is listening now?


*::DataListener::event*: **ev src args**

::

	generate event (call callback) for this listener.
	ev is ListenEvent object, src is the source of event.
	ev is one of run|stop|data|on|off|add|del:
	  run - before first packet sent
	  stop - after last packet sent
	  data - packet is received
	  on - enable listening
	  off - disable listening
	  add - connect with some data provider
	  del - disconnect from some data provider


*::DataListener::listen*: **what**

::

	listen -on -- turn-on listening
	listen -off -- turn-off listening


::Bpfir (*extends ::BaseFilter ::DataListener ::DataProvider*)
--------------------------------------------------------------

Variables
~~~~~~~~~

- protected ::Bpfir::this
- protected ::BaseFilter::COLUMNS
- protected ::BaseFilter::UNITS
- public ::DataListener::all
- public ::DataListener::datatypes
- public ::DataProvider::datatype
- public ::DataProvider::all

Methods
~~~~~~~

*::Bpfir::reset*: **no args.**

::

	Reset internal state


*::BaseFilter::chconfigure*: **args**

::

	Configure channels' filters:
	  -ord int|{int0 int1...} -- order of filter
	  -f1 double|{double0 double1...} -- cut freq 1
	  -f2 double|{double0 double1...} -- cut freq 2
	  -win bool|{bool0 bool1...} -- need Blackman window?
	  -norm bool|{bool0 bool1...} -- need normalization of coefficients?
	  -fs double|{double0 double1...} -- sampling freq (if omitted, sensor get_freq is used)
	
	Positional args are indexes of channels to be filtered or 'all'. Ex:
	
	  chconfigure 0 1 3 -f1 {10 20 30} -ord {15 20 25}
	
	All freqs are in Hz. Sampling freq is obtained from sensor when onrun is called.
	Without args, returns last chconfigure string


*::BaseFilter::get_cfir*: **i**

::

	Returns core FIR (on C in DLL) object


*::BaseFilter::reset*: **no args.**

::

	Reset internal state


*::DataListener::listened*: **no args.**

::

	Is listening now?


*::DataListener::event*: **ev src args**

::

	generate event (call callback) for this listener.
	ev is ListenEvent object, src is the source of event.
	ev is one of run|stop|data|on|off|add|del:
	  run - before first packet sent
	  stop - after last packet sent
	  data - packet is received
	  on - enable listening
	  off - disable listening
	  add - connect with some data provider
	  del - disconnect from some data provider


*::DataListener::listen*: **what**

::

	listen -on -- turn-on listening
	listen -off -- turn-off listening


*::DataProvider::get_listeners*: **no args.**

::

	Returns names of all listeners


*::DataProvider::del_listener*: **listener {stop 1}**

::

	Deletes listener, sends before stop event if needed


*::DataProvider::del_all_listeners*: **{stop 1}**

::

	Deletes all listeners, send stop event before, if needed


*::DataProvider::notify_all*: **ev args**

::

	Notify all listeners with event ev and some args


*::DataProvider::number*: **no args.**

::

	Returns number of listeners


*::DataProvider::add_listener*: **listener**

::

	Add some listener


::Serial
--------

Variables
~~~~~~~~~

- protected ::Serial::this

Methods
~~~~~~~

*::Serial::listened*: **no args.**

::

	Returns 1 if listened readable events, 0 otherwise


*::Serial::got*: **{what -size}**

::

	Returns incoming data as string with -data option or
	it's size with -size option but unlike read does not
	clear _inbuf


*::Serial::send*: **bytes**

::

	Sends bytes (like {0x53 0x30 ...}) sequence


*::Serial::open*: **port {mode 9600,n,8,1}**

::

	Opens port with name or number (1,2..) port and mode (like "9600,n,8,1")


*::Serial::closed*: **no args.**

::

	Is it closed?


*::Serial::opened*: **no args.**

::

	Is it opened?


*::Serial::read*: **args**

::

	Receive bytes from port. With -nb -- in NON-BLOCKED manner, but
	returns _inbuf (early readed asynchronously)


*::Serial::expect*: **nbytes body**

::

	Used for sending with waiting for nbytes bytes, ex.
	serial expect 6 { serial docmd SOME_CMD }


*::Serial::close*: **no args.**

::

	Safe closing of port (listening turn-off)


*::Serial::ls*: **{what -all}**

::

	Prints -all|-virt|-auto - detected COM-ports from Windows registry
	  -all - is without FriendlyName
	  -virt - virtual ports


*::Serial::listen*: **{enabled -on}**

::

	Turn-on/off listening of incoming bytes in async manner.
	  -on - enables listening
	  -off - disables listening


::Lpfir (*extends ::BaseFilter ::DataListener ::DataProvider*)
--------------------------------------------------------------

Variables
~~~~~~~~~

- protected ::Lpfir::this
- protected ::BaseFilter::COLUMNS
- protected ::BaseFilter::UNITS
- public ::DataListener::all
- public ::DataListener::datatypes
- public ::DataProvider::datatype
- public ::DataProvider::all

Methods
~~~~~~~

*::Lpfir::reset*: **no args.**

::

	Reset internal state


*::BaseFilter::chconfigure*: **args**

::

	Configure channels' filters:
	  -ord int|{int0 int1...} -- order of filter
	  -f1 double|{double0 double1...} -- cut freq 1
	  -f2 double|{double0 double1...} -- cut freq 2
	  -win bool|{bool0 bool1...} -- need Blackman window?
	  -norm bool|{bool0 bool1...} -- need normalization of coefficients?
	  -fs double|{double0 double1...} -- sampling freq (if omitted, sensor get_freq is used)
	
	Positional args are indexes of channels to be filtered or 'all'. Ex:
	
	  chconfigure 0 1 3 -f1 {10 20 30} -ord {15 20 25}
	
	All freqs are in Hz. Sampling freq is obtained from sensor when onrun is called.
	Without args, returns last chconfigure string


*::BaseFilter::get_cfir*: **i**

::

	Returns core FIR (on C in DLL) object


*::BaseFilter::reset*: **no args.**

::

	Reset internal state


*::DataListener::listened*: **no args.**

::

	Is listening now?


*::DataListener::event*: **ev src args**

::

	generate event (call callback) for this listener.
	ev is ListenEvent object, src is the source of event.
	ev is one of run|stop|data|on|off|add|del:
	  run - before first packet sent
	  stop - after last packet sent
	  data - packet is received
	  on - enable listening
	  off - disable listening
	  add - connect with some data provider
	  del - disconnect from some data provider


*::DataListener::listen*: **what**

::

	listen -on -- turn-on listening
	listen -off -- turn-off listening


*::DataProvider::get_listeners*: **no args.**

::

	Returns names of all listeners


*::DataProvider::del_listener*: **listener {stop 1}**

::

	Deletes listener, sends before stop event if needed


*::DataProvider::del_all_listeners*: **{stop 1}**

::

	Deletes all listeners, send stop event before, if needed


*::DataProvider::notify_all*: **ev args**

::

	Notify all listeners with event ev and some args


*::DataProvider::number*: **no args.**

::

	Returns number of listeners


*::DataProvider::add_listener*: **listener**

::

	Add some listener



Procedures
==========

*listen*: **args**

::

	Set who listen who:
	  listen provider...: listener...
	or
	  listen prov...: all
	or
	  listen -- return list of lists {provider {listeners}}
	or
	  listen -txt -- return formatted string (for user)
	or
	  listen -p -- returns formatted string with providers and it's datatypes
	or
	  listen -l -- returns formatted string with listeners and it's datatypes


*reset_dsp*: **no args.**

::

	Reset internal state of all DSP components

