 # Goal: SpyglassConvergedLintSOC

set saved_sh_continue_on_error [get_app_var sh_continue_on_error]

set_app_var sh_continue_on_error true


configure_lint_tag -enable -tag "badimplicitSM1" -severity Error

configure_lint_tag -enable -tag "badimplicitSM2" -severity Error

configure_lint_tag -enable -tag "badimplicitSM4" -severity Error

configure_lint_tag -enable -tag "BlockHeader" -severity Warning

configure_lint_tag -enable -tag "bothedges" -severity Error

configure_lint_tag -enable -tag "STARC05-2.1.6.5" -severity Error

configure_lint_tag -enable -tag "STARC05-2.3.1.2c" -severity Error

configure_lint_tag -enable -tag "W421"  -severity Error

configure_lint_tag -enable -tag "W442a"  -severity Error

configure_lint_tag -enable -tag "W442b"  -severity Error

configure_lint_tag -enable -tag "sim_race02" -severity Error

configure_lint_tag_parameter -tag "sim_race02" -parameter WAIVER_COMPAT -value {W143}

configure_lint_tag -enable -tag "W110a"  -severity Error

configure_lint_tag -enable -tag "W416"  -severity Error

configure_lint_tag -enable -tag "W416" -type_id SG_LINT_W416_VERILOG_W416_VE_ORDER_DEADCODE -severity Warning

configure_lint_tag -enable -tag "W416" -type_id SG_LINT_W416_VERILOG_W416_VE_WIDTH_DEADCODE -severity Warning

configure_lint_tag_parameter -tag "W416" -parameter CHECK_STATIC_VALUE -value {yes}

configure_lint_tag_parameter -tag "W416" -parameter ENABLE_RTL_DEADCODE -value {yes}

configure_lint_tag_parameter -tag "W416" -parameter HANDLE_ZERO_PADDING -value {yes}

configure_lint_tag_parameter -tag "W416" -parameter IGNORE_NONSTATIC_COUNTER -value {yes}

configure_lint_tag_parameter -tag "W416" -parameter CHECK_COUNTER_ASSIGNMENT -value {yes}

configure_lint_tag_parameter -tag "W416" -parameter NOCHECKOVERFLOW  -value {no}

configure_lint_tag -enable -tag "PragmaComments-ML" -severity Warning

configure_lint_tag -enable -tag "STARC05-2.10.2.3" -severity Error

configure_lint_tag -enable -tag "STARC05-2.11.3.1" -severity Warning

configure_lint_tag_parameter -tag "STARC05-2.11.3.1" -parameter STRICT -value {no}

configure_lint_tag -enable -tag "STARC05-2.3.1.5b" -severity Error

configure_lint_tag -enable -tag "W215"  -severity Error

configure_lint_tag -enable -tag "W216"  -severity Error

configure_lint_tag -enable -tag "W289"  -severity Error

configure_lint_tag -enable -tag "W292"  -severity Error

configure_lint_tag -enable -tag "W293"  -severity Error

configure_lint_tag -enable -tag "W317"  -severity Error

configure_lint_tag -enable -tag "W352"  -severity Error

configure_lint_tag -enable -tag "W398"  -severity Error

configure_lint_tag_parameter -tag "W398" -parameter STRICT -value {no}

configure_lint_tag_parameter -tag "W398" -parameter WAIVER_COMPAT -value {W143}

configure_lint_tag -enable -tag "W422"  -severity Error

configure_lint_tag -enable -tag "W424"  -severity Error

configure_lint_tag -enable -tag "W425"  -severity Error

configure_lint_tag -enable -tag "W426"  -severity Error

configure_lint_tag -enable -tag "W427"  -severity Error

configure_lint_tag -enable -tag "W428"  -severity Error

configure_lint_tag -enable -tag "STARC05-2.1.2.4" -severity Error

configure_lint_tag_parameter -tag "STARC05-2.1.2.4" -parameter IGNORE_SYSTEM_TASKS -value {yes}

configure_lint_tag -enable -tag "InterfaceWithoutModport-ML" -severity Error

configure_lint_tag -enable -tag "W467"  -severity Error

configure_lint_tag_parameter -tag "W467" -parameter IGNORE_PARAM_CASE_CONDITION -value {yes}

configure_lint_tag -enable -tag "W481a"  -severity Error

configure_lint_tag_parameter -tag "W481a" -parameter STRICT -value {no}

configure_lint_tag -enable -tag "W481b"  -severity Error

configure_lint_tag -enable -tag "W496a"  -severity Error

configure_lint_tag -enable -tag "W496b"  -severity Error

configure_lint_tag -enable -tag "W71"  -severity Error

configure_lint_tag_parameter -tag "W71" -parameter CHECK_SEQUENTIAL -value {yes}

configure_lint_tag_parameter -tag "W71" -parameter STRICT -value {no}

configure_lint_tag_parameter -tag "W71" -parameter REPORT_ONLY_FROM_ONE_HIERARCHY -value {yes}

configure_lint_tag -enable -tag "NoAssignX-ML" -severity Error

configure_lint_tag_parameter -tag "NoAssignX-ML" -parameter ADD_SIGNATURE_EXPRESSION -value {yes}

configure_lint_tag_parameter -tag "NoAssignX-ML" -parameter CHECK_ENUM_DECL -value {yes}

configure_lint_tag_parameter -tag "NoAssignX-ML" -parameter CHECK_XASSIGN_CASEDEFAULT -value {yes}

configure_lint_tag -enable -tag "ReportPortInfo-ML" -severity Info

configure_lint_tag -enable -tag "STARC05-2.1.3.1" -severity Error

configure_lint_tag_parameter -tag "STARC05-2.1.3.1" -parameter NOCHECKOVERFLOW -value {no}

configure_lint_tag -enable -tag "STARC05-2.2.3.3" -severity Error

configure_lint_tag_parameter -tag "STARC05-2.2.3.3" -parameter STRICT -value {no}

configure_lint_tag -enable -tag "STARC05-2.3.1.6" -severity Error

configure_lint_tag -enable -tag "W116"  -severity Error

configure_lint_tag -enable -tag "W116" -type_id SG_LINT_W116_VERILOG_LINT_W116_DEADCODE -severity Warning

configure_lint_tag_parameter -tag "W116" -parameter CHECK_COUNTER_ASSIGNMENT -value {yes}

configure_lint_tag_parameter -tag "W116" -parameter CHECK_STATIC_VALUE -value {yes}

configure_lint_tag_parameter -tag "W116" -parameter ENABLE_RTL_DEADCODE -value {yes}

configure_lint_tag_parameter -tag "W116" -parameter IGNORE_NONSTATIC_COUNTER -value {yes}

configure_lint_tag_parameter -tag "W116" -parameter NOCHECKOVERFLOW -value {no}

configure_lint_tag_parameter -tag "W116" -parameter REPORTCONSTASSIGN -value {yes}

configure_lint_tag_parameter -tag "W116" -parameter STRICT -value {no}

configure_lint_tag_parameter -tag "W116" -parameter REPORT_ONLY_FROM_ONE_HIERARCHY -value {yes}

configure_lint_tag -enable -tag "W122"  -severity Error

configure_lint_tag_parameter -tag "W122" -parameter STRICT -value {no}

configure_lint_tag -enable -tag "W123"  -severity Error

configure_lint_tag -enable -tag "W123"  -type_id SG_LINT_W123_VHDL_SIGNALUSAGEREPORT_REFER -severity Info

configure_lint_tag -enable -tag "W123"  -type_id SG_LINT_W123_VERILOG_SIGNALUSAGEREPORT_REFER -severity Info

configure_lint_tag_parameter -tag "W123" -parameter CHECKFULLRECORD -value {yes}

configure_lint_tag_parameter -tag "W123" -parameter HANDLE_LARGE_BUS -value {yes}

configure_lint_tag_parameter -tag "W123" -parameter IGNOREMODULEINSTANCE -value {yes}

configure_lint_tag_parameter -tag "W123" -parameter REPORT_STRUCT_NAME_ONLY -value {yes}

configure_lint_tag_parameter -tag "W123" -parameter REPORT_ONLY_FROM_ONE_HIERARCHY -value {yes}

configure_lint_tag -enable -tag "W19"  -severity Error

configure_lint_tag_parameter -tag "W19" -parameter STRICT -value {no}

configure_lint_tag -enable -tag "W218"  -severity Error

configure_lint_tag -enable -tag "W240"  -severity Warning

configure_lint_tag -enable -tag "W240" -type_id SG_LINT_W240_VERILOG_SIGNALUSAGEREPORT_REFER -severity Info

configure_lint_tag -enable -tag "W240" -type_id SG_LINT_W240_VHDL_SIGNALUSAGEREPORT_REFER -severity Info

configure_lint_tag_parameter -tag "W240" -parameter CHECKFULLRECORD -value {yes}

configure_lint_tag_parameter -tag "W240" -parameter HANDLE_LARGE_BUS -value {yes}

configure_lint_tag_parameter -tag "W240" -parameter REPORT_ONLY_FROM_ONE_HIERARCHY -value {yes}

configure_lint_tag -enable -tag "W263"  -severity Error

configure_lint_tag_parameter -tag "W263" -parameter NOCHECKOVERFLOW -value {no}

configure_lint_tag_parameter -tag "W263" -parameter STRICT -value {no}

configure_lint_tag -enable -tag "W337"  -severity Error

configure_lint_tag_parameter -tag "W337" -parameter STRICT -value {no}

configure_lint_tag -enable -tag "W486"  -severity Error

configure_lint_tag -enable -tag "W486" -type_id SG_LINT_W486_VERILOG_W486_VE_DEADCODE -severity Warning

configure_lint_tag_parameter -tag "W486" -parameter ENABLE_RTL_DEADCODE -value {yes}

configure_lint_tag_parameter -tag "W486" -parameter NOCHECKOVERFLOW -value {no}

configure_lint_tag_parameter -tag "W486" -parameter PROCESS_COMPLETE_CONDOP -value {yes}

configure_lint_tag -enable -tag "W499"  -severity Error

configure_lint_tag -enable -tag "W499" -type_id SG_LINT_W499_VERILOG_SIGNALUSAGEREPORT_REFER -severity Info

configure_lint_tag_parameter -tag "W499" -parameter HANDLE_LARGE_BUS -value {yes}

configure_lint_tag_parameter -tag "W499" -parameter IGNORE_AUTO_FUNCTION_RETURN -value {yes}

configure_lint_tag -enable -tag "W502"  -severity Error

configure_lint_tag -enable -tag "W505"  -severity Error

configure_lint_tag -enable -tag "W66"  -severity Error

configure_lint_tag -enable -tag "InferLatch" -severity Error

configure_lint_tag -enable -tag "InferLatch" -type_id SG_OPENMORE_INFERLATCH_VERILOG_INFERLATCH -severity Error

configure_lint_tag -enable -tag "InferLatch" -type_id SG_OPENMORE_INFERLATCH_MIXED_INFERLATCH -severity Error

configure_lint_tag -enable -tag "InferLatch" -type_id SG_OPENMORE_INFERLATCH_MIXED_INFERLATCH_FOR_REPORTLATCHHIERARCHY -severity Warning

configure_lint_tag -enable -tag "InferLatch" -type_id SG_OPENMORE_INFERLATCH_MIXED_INFERLATCH_HL -severity Warning

configure_lint_tag_parameter -tag "InferLatch" -parameter IGNOREREALLATCH -value {yes}

configure_lint_tag_parameter -tag "InferLatch" -parameter STRICT -value {no}

#configure_lint_tag_parameter -tag "InferLatch" -parameter REPORTHANGINGLATCH -value {yes}

configure_lint_tag -enable -tag "STARC05-2.5.1.7" -severity Error

configure_lint_tag -enable -tag "STARC05-2.5.1.9" -severity Error

configure_lint_tag -enable -tag "STARC05-2.10.3.2a" -severity Warning

configure_lint_tag_parameter -tag "STARC05-2.10.3.2a" -parameter ENABLE_RTL_DEADCODE -value {yes}

configure_lint_tag_parameter -tag "STARC05-2.10.3.2a" -parameter NOCHECKOVERFLOW -value {no}

configure_lint_tag_parameter -tag "STARC05-2.10.3.2a" -parameter CHECK_STATIC_VALUE -value {yes}

configure_lint_tag -enable -tag "W336"  -severity Error

configure_lint_tag_parameter -tag "W336" -parameter CHECK_TEMPORARY_FLOP -value {yes}

configure_lint_tag_parameter -tag "W336" -parameter IGNORECELLNAME -value {ctech_lib_clk_ffb,ctech_lib_clk_ffb_rstb,ctech_lib_clk_divider2,ctech_lib_clk_divider2_rstb}

configure_lint_tag -enable -tag "W414"  -severity Error

configure_lint_tag -enable -tag "W450L"  -severity Error

configure_lint_tag -enable -tag "UndrivenInTerm-ML" -severity Error

configure_lint_tag_parameter -tag "UndrivenInTerm-ML" -parameter CHECKINHIERARCHY -value {yes}

configure_lint_tag_parameter -tag "UndrivenInTerm-ML" -parameter CHECKRTLCINST -value {yes}

configure_lint_tag_parameter -tag "UndrivenInTerm-ML" -parameter IGNORERTLBUFFER -value {yes}

configure_lint_tag_parameter -tag "UndrivenInTerm-ML" -parameter IGNORE_DELIBERATELY_UNCONNECTED -value {yes}

configure_lint_tag_parameter -tag "UndrivenInTerm-ML" -parameter IGNORE_UNUSED_FLOP -value {yes}

configure_lint_tag -enable -tag "CombLoop" -severity Error

configure_lint_tag -enable -tag "CombLoop" -type_id SG_OPENMORE_COMBLOOP_MIXED_COMBLOOP_MORE_LATCH -severity Warning

configure_lint_tag -enable -tag "CombLoop" -type_id SG_OPENMORE_COMBLOOP_MIXED_COMBLOOPRPT -severity Info

configure_lint_tag_parameter -tag "CombLoop" -parameter ALLVIOL -value {yes}

configure_lint_tag_parameter -tag "CombLoop" -parameter ENABLEE2Q -value {yes}

configure_lint_tag_parameter -tag "CombLoop" -parameter ENABLE_LATCH_BASED_CLUSTERS -value {yes}

configure_lint_tag_parameter -tag "CombLoop" -parameter IGNORE_INTERNAL_LOOPS -value {yes}

configure_lint_tag_parameter -tag "CombLoop" -parameter REPORT_FLOP_RESET_LOOP -value {yes}

configure_lint_tag_parameter -tag "CombLoop" -parameter STRICT -value {no}

configure_lint_tag -enable -tag "FlopClockConstant" -severity Error

configure_lint_tag_parameter -tag "FlopClockConstant" -parameter ALLVIOL -value {yes}

configure_lint_tag_parameter -tag "FlopClockConstant" -parameter IGNORE_HANGING_FLOP -value {yes}

configure_lint_tag_parameter -tag "FlopClockConstant" -parameter REPORT_CONST_CONNECT -value {yes}

configure_lint_tag_parameter -tag "FlopClockConstant" -parameter REPORT_INFERRED_CELL -value {yes}

#configure_lint_tag_parameter -tag "FlopClockConstant" -parameter REPORT_IMMEDIATE_SRC -value {yes}

configure_lint_tag -enable -tag "FlopEConst" -severity Error

configure_lint_tag_parameter -tag "FlopEConst" -parameter ALLVIOL -value {yes}

configure_lint_tag_parameter -tag "FlopEConst" -parameter IGNORE_HANGING_FLOP -value {yes}

configure_lint_tag_parameter -tag "FlopEConst" -parameter REPORT_CONST_CONNECT -value {yes}

configure_lint_tag_parameter -tag "FlopEConst" -parameter REPORT_INFERRED_CELL -value {yes}

#configure_lint_tag_parameter -tag "FlopEConst" -parameter REPORT_IMMEDIATE_SRC -value {yes}

configure_lint_tag -enable -tag "FlopSRConst" -severity Error

configure_lint_tag_parameter -tag "FlopSRConst" -parameter ALLVIOL -value {yes}

configure_lint_tag_parameter -tag "FlopSRConst" -parameter IGNORE_HANGING_FLOP -value {yes}

configure_lint_tag_parameter -tag "FlopSRConst" -parameter REPORT_INFERRED_CELL -value {yes}

#configure_lint_tag_parameter -tag "FlopSRConst" -parameter REPORT_IMMEDIATE_SRC -value {yes}

configure_lint_tag -enable -tag "LatchFeedback" -severity Warning

configure_lint_tag -enable -tag "STARC05-1.2.1.2" -severity Error

configure_lint_tag -enable -tag "STARC05-1.4.3.4" -severity Error

configure_lint_tag_parameter -tag "STARC05-1.4.3.4" -parameter REPORT_ALLCLK -value {no}

configure_lint_tag_parameter -tag "STARC05-1.4.3.4" -parameter REPORT_ALLCLK_OPTIMIZED -value {no}

configure_lint_tag -enable -tag "STARC05-2.1.4.5" -severity Error

configure_lint_tag -enable -tag "STARC05-2.4.1.5" -severity Error

configure_lint_tag_parameter -tag "STARC05-2.4.1.5" -parameter IGNORE_MUX_CELL -value {yes}

configure_lint_tag_parameter -tag "STARC05-2.4.1.5" -parameter COMBO_DEPTH -value {1}

configure_lint_tag -enable -tag "STARC05-2.5.1.2" -severity Error

configure_lint_tag_parameter -tag "STARC05-2.5.1.2" -parameter STRICT -value {no}

configure_lint_tag -enable -tag "W415" -severity Error

configure_lint_tag -enable -tag "W415" -type_id SG_LINT_W415_MIXED_W415RPT -severity Info

configure_lint_tag_parameter -tag "W415" -parameter ASSUME_DRIVER_LOAD -value {yes}

configure_lint_tag_parameter -tag "W415" -parameter CHECKCONSTASSIGN -value {yes}

configure_lint_tag_parameter -tag "W415" -parameter HANDLE_EQUIVALENT_DRIVERS -value {yes}

configure_lint_tag_parameter -tag "W415" -parameter STRICT -value {no}

configure_lint_tag -enable -tag "STARC05-2.10.1.4a" -severity Error

configure_lint_tag_parameter -tag "STARC05-2.10.1.4a" -parameter CHECK_ANY_BIT_FOR_XZ -value {yes}

configure_lint_tag_parameter -tag "STARC05-2.10.1.4a" -parameter IGNORE_QMARK -value {yes}

configure_lint_tag -enable -tag "STARC05-2.10.1.4b" -severity Error

configure_lint_tag_parameter -tag "STARC05-2.10.1.4b" -parameter IGNORE_CASE_COMPARE_OP -value {1}

configure_lint_tag -enable -tag "W156" -severity Warning

configure_lint_tag_parameter -tag "W156" -parameter STRICT -value {no}

configure_lint_tag -enable -tag "STARC05-2.3.3.1" -severity Error

configure_lint_tag -enable -tag "W287b" -severity Warning

configure_lint_tag -enable -tag "W224"  -severity Error

configure_lint_tag_parameter -tag "W224" -parameter USE_NATURAL_WIDTH -value {yes}

configure_lint_tag_parameter -tag "W224" -parameter REPORT_ONLY_FROM_ONE_HIERARCHY -value {yes}

configure_lint_tag -enable -tag "W287a" -severity Warning

configure_lint_tag_parameter -tag "W287a" -parameter STRICT -value {no}

configure_lint_tag_parameter -tag "W287a" -parameter REPORT_ONLY_FROM_ONE_HIERARCHY -value {yes}

configure_lint_tag -enable -tag "mixedsenselist" -severity Warning

configure_lint_tag -enable -tag "W339a"  -severity Error

configure_lint_tag -enable -tag "W430"  -severity Warning

configure_lint_tag -enable -tag "W257"  -severity Error

configure_lint_tag_parameter -tag "W257" -parameter ALLVIOL -value {yes}

configure_lint_tag -enable -tag "W294"  -severity Error

configure_lint_tag -enable -tag "NoStrengthInput-ML" -severity Error

configure_lint_tag -enable -tag "STARC05-3.2.4.3" -severity Error

configure_lint_tag -enable -tag "W182g"  -severity Error

configure_lint_tag -enable -tag "W182h"  -severity Error

configure_lint_tag -enable -tag "W182k"  -severity Error

configure_lint_tag -enable -tag "W182n"  -severity Error

configure_lint_tag -enable -tag "W213"  -severity Error

configure_lint_tag_parameter -tag "W213" -parameter IGNORE_PLI_TASKS_AND_FUNCTIONS -value {display,info,warning,error,fatal}

configure_lint_tag -enable -tag "1490"  -severity Error

configure_lint_tag -enable -tag "1492"  -severity Error

configure_lint_tag -enable -tag "2082"  -severity Error

configure_lint_tag -enable -tag "02041"  -severity Error

configure_lint_tag_parameter -tag "02041" -parameter CHECK_DECL_IN_FUNC -value {yes}

configure_lint_tag -enable -tag "UnrecSynthDir-ML" -severity Warning

configure_lint_tag_parameter -tag "UnrecSynthDir-ML" -parameter CHECK_ALL_PRAGMAS -value {yes}

configure_lint_tag -enable -tag "W495"  -severity Warning

configure_lint_tag_parameter -tag "W495" -parameter HANDLE_LARGE_BUS -value {yes}

configure_lint_tag -enable -tag "W120"  -severity Warning

configure_lint_tag -enable -tag "W120" -type_id SG_LINT_W120_VHDL_SIGNALUSAGEREPORT_REFER -severity Info

configure_lint_tag -enable -tag "W120" -type_id SG_LINT_W120_VERILOG_SIGNALUSAGEREPORT_REFER -severity Info

configure_lint_tag_parameter -tag "W120" -parameter CHECKFULLRECORD -value {yes}

configure_lint_tag_parameter -tag "W120" -parameter HANDLE_LARGE_BUS -value {yes}

configure_lint_tag_parameter -tag "W120" -parameter REPORT_ONLY_FROM_ONE_HIERARCHY -value {yes}

configure_lint_tag -enable -tag "W241"  -severity Warning

configure_lint_tag -enable -tag "W241" -type_id SG_LINT_W241_VERILOG_SIGNALUSAGEREPORT_REFER -severity Info

configure_lint_tag -enable -tag "W241" -type_id SG_LINT_W241_VHDL_SIGNALUSAGEREPORT_REFER -severity Info

configure_lint_tag_parameter -tag "W241" -parameter HANDLE_LARGE_BUS -value {yes}

configure_lint_tag -enable -tag "W494"  -severity Warning

configure_lint_tag_parameter -tag "W494" -parameter CHKTOPMODULE -value {yes}

configure_lint_tag_parameter -tag "W494" -parameter HANDLE_LARGE_BUS -value {yes}

configure_lint_tag_parameter -tag "W494" -parameter STRICT -value {no}

configure_lint_tag -enable -tag "UnloadedOutTerm-ML" -severity Warning

configure_lint_tag_parameter -tag "UnloadedOutTerm-ML" -parameter CHECKINHIERARCHY -value {yes}

configure_lint_tag_parameter -tag "UnloadedOutTerm-ML" -parameter IGNORERTLBUFFER -value {yes}

configure_lint_tag_parameter -tag "UnloadedOutTerm-ML" -parameter IGNORE_DELIBERATELY_UNCONNECTED -value {yes}

configure_lint_tag -enable -tag "UnloadedInPort-ML" -severity Warning

configure_lint_tag_parameter -tag "UnloadedInPort-ML" -parameter CHECKINHIERARCHY -value {yes}

configure_lint_tag_parameter -tag "UnloadedInPort-ML" -parameter IGNORERTLBUFFER -value {yes}

configure_lint_tag -enable -tag "UndrivenOutPort-ML" -severity Error

configure_lint_tag_parameter -tag "UndrivenOutPort-ML" -parameter CHECKINHIERARCHY -value {yes}

configure_lint_tag_parameter -tag "UndrivenOutPort-ML" -parameter IGNORERTLBUFFER -value {yes}

configure_lint_tag -enable -tag "UndrivenNUnloaded-ML" -severity Warning

configure_lint_tag_parameter -tag "UndrivenNUnloaded-ML" -parameter CHECKINHIERARCHY -value {yes}

configure_lint_tag_parameter -tag "UndrivenNUnloaded-ML" -parameter IGNORERTLBUFFER -value {yes}

configure_lint_tag -enable -tag "UndrivenOutTermNLoaded-ML" -severity Error

configure_lint_tag_parameter -tag "UndrivenOutTermNLoaded-ML" -parameter CHECKINHIERARCHY -value {yes}

configure_lint_tag -enable -tag "UnloadedNet-ML" -severity Warning

configure_lint_tag_parameter -tag "UnloadedNet-ML" -parameter CHECKINHIERARCHY -value {yes}

configure_lint_tag_parameter -tag "UnloadedNet-ML" -parameter IGNORERTLBUFFER -value {yes}

configure_lint_tag -enable -tag "LatchEnableConstant" -severity Error

#configure_lint_tag_parameter -tag "LatchEnableConstant" -parameter REPORT_IMMEDIATE_SRC -value {yes}

configure_lint_tag_parameter -tag "LatchEnableConstant" -parameter ALLVIOL -value {yes}

configure_lint_tag -enable -tag "LatchEnableUndriven" -severity Error

configure_lint_tag_parameter -tag "LatchEnableUndriven" -parameter ALLVIOL -value {yes}

configure_lint_tag_parameter -tag "W210" -parameter SET_MESSAGE_SEVERITY -value {yes}

configure_lint_tag -enable -tag "W210" -type_id SG_LINT_W210_VHDL_MISSING_PORT_ERROR -severity Error

configure_lint_tag -enable -tag "W210" -type_id SG_LINT_W210_VERILOG_MISSING_PORT_ERROR -severity Error

configure_lint_tag -enable -tag "W210" -type_id SG_LINT_W210_VHDL_MISSING_PORT_WARNING -severity Warning

configure_lint_tag -enable -tag "W210" -type_id SG_LINT_W210_VERILOG_MISSING_PORT_WARNING -severity Warning

configure_lint_tag -enable -tag "60004"  -severity Error

configure_lint_tag -enable -tag "60006"  -severity Error

configure_lint_tag -enable -tag "UndrivenNet-ML" -severity Warning

configure_lint_tag_parameter -tag "UndrivenNet-ML" -parameter CHECKINHIERARCHY -value {yes}

configure_lint_tag_parameter -tag "UndrivenNet-ML" -parameter IGNORERTLBUFFER -value {yes}

configure_lint_tag_parameter -tag "UndrivenNet-ML" -parameter IGNORE_UNUSED_FLOP -value {yes}

configure_lint_tag -enable -tag "NoExprInPort-ML" -severity Info

configure_lint_tag_parameter -tag "NoExprInPort-ML" -parameter CHECKGATEINST -value {yes}

configure_lint_tag_parameter -tag "NoExprInPort-ML" -parameter IGNOREINVERSIONOPERATION -value {yes}

configure_lint_tag -enable -tag "NamedAssoc" -severity Error

configure_lint_tag -enable -tag "AssignPatInInst-ML" -severity Error

configure_lint_tag -enable -tag "60013"  -severity Error

configure_lint_tag_parameter -tag "60013" -parameter PERMIT_SIMILAR_NAMES_AMONGST_DIFFERENT_OBJECT_TYPES -value {1}

configure_lint_tag -enable -tag "ParamName" -severity Warning

configure_lint_tag_parameter -tag "ParamName" -parameter PARAMNAME -value {/^[A-Z][0-9A-Z]*/ and not /[a-z]/}

configure_lint_tag -enable -tag "SigName"  -severity Warning

configure_lint_tag_parameter -tag "SigName" -parameter PRINT_RECOMMENDED_REGEXP -value {yes}

configure_lint_tag_parameter -tag "SigName" -parameter SIGNAME -value {/^[a-zA-Z]([a-zA-Z0-9_])*$/ and /^.{1,1024}$/ and not /__/}

configure_lint_tag -enable -tag "PortName" -severity Warning

configure_lint_tag_parameter -tag "PortName" -parameter IGNORE_FILE -value {.*\.binc\.vs|.*\.tinc\.vs|.*\.ports\.v}

configure_lint_tag_parameter -tag "PortName" -parameter PORTNAME -value {/^[a-zA-Z]([a-zA-Z0-9_])*$/ and /^.{1,128}$/ and not /__/}

configure_lint_tag_parameter -tag "PortName" -parameter PRINT_RECOMMENDED_REGEXP -value {yes}

configure_lint_tag -enable -tag "VarName"  -severity Warning

configure_lint_tag_parameter -tag "VarName" -parameter PRINT_RECOMMENDED_REGEXP -value {yes}

configure_lint_tag_parameter -tag "VarName" -parameter VARNAME -value {/^[a-zA-Z]([a-zA-Z0-9_])*$/ and /^.{1,1024}$/ and not /__/}

configure_lint_tag -enable -tag "ConstName" -severity Warning

configure_lint_tag_parameter -tag "ConstName" -parameter CONSTNAME -value {/^[A-Z][A-Z0-9_]*$/}

configure_lint_tag_parameter -tag "ConstName" -parameter PRINT_RECOMMENDED_REGEXP -value {yes}

configure_lint_tag -enable -tag "W121"  -severity Error

configure_lint_tag_parameter -tag "W121" -parameter IGNORE_MACRO_TO_NONMACRO -value {yes}

configure_lint_tag_parameter -tag "W121" -parameter LIMIT_TASK_FUNCTION_SCOPE -value {yes}

configure_lint_tag_parameter -tag "W121" -parameter WAIVER_COMPAT -value {W143}

configure_lint_tag -enable -tag "STARC05-1.1.1.2" -severity Warning

configure_lint_tag_parameter -tag "STARC05-1.1.1.2" -parameter IGNORE_FILE -value {.*\.binc\.vs|.*\.tinc\.vs|.*\.ports\.v}

configure_lint_tag_parameter -tag "STARC05-1.1.1.2" -parameter REPORT_TYPEDEF -value {yes}

configure_lint_tag -enable -tag "STARC05-1.1.1.3" -severity Error

configure_lint_tag_parameter -tag "STARC05-1.1.1.3" -parameter DISABLE_VHDL_KEYWORDS -value {yes}

configure_lint_tag -enable -tag "60117"  -severity Error

configure_lint_tag_parameter -tag "60117" -parameter REGEXP_FORBIDDEN_MACROS -value {^((?:LS_\w*)$|ISO_(HIGH|LOW)|AND_ISO|EPG).*}

configure_lint_tag -enable -tag "60010"  -severity Error

configure_lint_tag_parameter -tag "60010" -parameter REPORT_OBJECT_TYPES -value {net,port,variable,struct,union,enum,typedef,userdefined}

configure_lint_tag_parameter -tag "60010" -parameter KEYWORDS -value {^semaphore$ ^gnd$ ^above$ ^abs$ ^absdelay$ ^acos$ ^acosh$ ^ac_stim$ ^aliasparam$ ^analog$ ^analysis$ ^asin$ ^asinh$ ^atan$ ^atan2$ ^atanh$ ^branch$ ^ceil$ ^connectrules$ ^cos$ ^cosh$ ^ddt$ ^ddx$ ^discipline$ ^driver_update$ ^enddiscipline$ ^endconnectrules$ ^exclude$ ^exp$ ^final_step$ ^flicker_noise$ ^floor$ ^flow$ ^from$ ^ground$ ^hypot$ ^idt$ ^idtmod$ ^inf$ ^initial_step$ ^laplace_nd$ ^laplace_np$ ^laplace_zd$ ^laplace_zp$ ^last_crossing$ ^limexp$ ^ln$ ^log$ ^max$ ^min$ ^nature$ ^net_resolution$ ^noise_table$ ^paramset$ ^potential$ ^pow$ ^pulldown$ ^sin$ ^sinh$ ^slew$ ^tan$ ^tanh$ ^timer$ ^transition$ ^white_noise$ ^wreal$ ^zi_nd$ ^zi_np$ ^zi_zd$ ^VCC ^vcc ^VDD ^vdd ^VSS ^vss}

configure_lint_tag -enable -tag "AlwaysEnabledCG"  -severity Error

configure_lint_tag -enable -tag "AlwaysDisabledCG"  -severity Error

configure_lint_tag -enable -tag "FewSeqOnCG"  -severity Warning

configure_lint_tag -enable -tag "54005" -severity Error

configure_lint_tag_parameter -tag "54005" -parameter BIST_CMP_REGEX -value {.*BIST_CMP.*}

configure_lint_tag_parameter -tag "54005" -parameter BIST_REN_REGEX -value {.*BIST_REN.*}

configure_lint_tag_parameter -tag "54005" -parameter ENABLE_SANITY_CHECK -value {1}

configure_lint_tag_parameter -tag "54005" -parameter EXCLUDE_REGEX -value {.*ungated.*|.*fwls.*|.*dfx_mbist.*}

configure_lint_tag -enable -tag "54006"  -severity Error

configure_lint_tag_parameter -tag "54006" -parameter EXCLUDE_REGEX -value {.*ungated.*|.*fwls.*|.*dfx_mbist.*}

configure_lint_tag -enable -tag "54007"  -severity Error

configure_lint_tag_parameter -tag "54007" -parameter EXCLUDE_REGEX -value {.*ungated.*|.*fwls.*|.*dfx_mbist.*}

configure_lint_tag -enable -tag "54009"  -severity Error

configure_lint_tag -enable -tag "60701"  -severity Error

configure_lint_tag_parameter -tag "60701" -parameter MODULES_REGEXP -value {^(b12.*|d04.*|b05.*|b14.*|b15.*|cc0.*|ec0.*|e05.*|yc8.*|fa0.*|f05.*)}

configure_lint_tag -enable -tag "60152"  -severity Error

configure_lint_tag_parameter -tag "60152" -parameter PATTERN_REGEXP -value {(.*ctech.*|.*_macro_tech_map\.vh$)}

configure_lint_tag -enable -tag "60702"  -severity Error

configure_lint_tag_parameter -tag "60702" -parameter CTECH_LIB_REGEXP -value {^ctech_lib.*|^Ctech_lib.*}

configure_lint_tag_parameter -tag "60702" -parameter MAP_FILE_REGEXP -value {(\w+)_map\.(v|sv)$}

configure_lint_tag -enable -tag "60703"  -severity Error

configure_lint_tag_parameter -tag "60703" -parameter CTECH_LIB_REGEXP -value {^ctech_lib.*|^Ctech_lib.*}

configure_lint_tag_parameter -tag "60703" -parameter MAP_FILE_REGEXP -value {(\w+)_map\.(v|sv)$}

configure_lint_tag -enable -tag "60704"  -severity Info

configure_lint_tag_parameter -tag "60704" -parameter CTECH_LIB_REGEXP -value {^ctech_lib.*|^Ctech_lib.*}

configure_lint_tag_parameter -tag "60704" -parameter MAP_FILE_REGEXP -value {(\w+)_map\.(v|sv)$}

configure_lint_tag -enable -tag "60706"  -severity Error

configure_lint_tag_parameter -tag "60706" -parameter CTECH_LIB_REGEXP -value {^ctech_lib.*|^Ctech_lib.*}

configure_lint_tag_parameter -tag "60706" -parameter EXCLUDE_FILE -value {/nfs/site/disks/hdk_.*|/nfs/site/proj/tech1/.*}

configure_lint_tag_parameter -tag "60706" -parameter EXCLUDE_PATH -value {/p/hdk/cad/ctech/.*|/nfs/site/disks/crt_tools.*|/nfs/site/disks/.crt_tools.*|/nfs/site/disks/hdk.cad.*|/nfs/site/disks/hdk_stdroot.*|/p/hdk/cad/stdcells/.*|/nfs/site/disks/crt_stdcells.*}

configure_lint_tag_parameter -tag "60706" -parameter MAP_FILE_REGEXP -value {(\w+)_map\.(v|sv)$}

configure_lint_tag -enable -tag "70600"  -severity Error

configure_lint_tag_parameter -tag "70600" -parameter DFT_ARRAYMODULES_REGEXP -value {.*dfx_wrapper|.*MSWT_WRP}

configure_lint_tag_parameter -tag "70600" -parameter VISA_MODULES_REGEXP -value {visa_(iomapper|unit|partition|repeater|central)_[0-9a-z_]+}

configure_lint_tag_parameter -tag "70600" -parameter VISA_MODULES_TO_IGNORE -value {visa_clk_mux,visa_mux_stage,visa_lane_mux,visa_lane_mux_slider}

configure_lint_tag -enable -tag "70601"  -severity Error

configure_lint_tag_parameter -tag "70601" -parameter VISA_INPUT_PORT2_CHECKREGEXP -value {lane_in}

configure_lint_tag_parameter -tag "70601" -parameter VISA_MODULES_REGEXP -value {visa_(iomapper|unit|partition|repeater|central)_[0-9a-z_]+}

configure_lint_tag_parameter -tag "70601" -parameter VISA_MODULES_TO_IGNORE -value {visa_clk_mux,visa_mux_stage,visa_lane_mux,visa_lane_mux_slider}

configure_lint_tag_parameter -tag "70601" -parameter REPORT_OVERLAPPING_PATHS -value {yes}

configure_lint_tag -enable -tag "70602"  -severity Error

configure_lint_tag_parameter -tag "70602" -parameter VISA_INPUT_PORT2_CHECKREGEXP -value {lane_in}

configure_lint_tag_parameter -tag "70602" -parameter VISA_MODULES_REGEXP -value {visa_(iomapper|unit|partition|repeater|central)_[0-9a-z_]+}

configure_lint_tag_parameter -tag "70602" -parameter VISA_MODULES_TO_IGNORE -value {visa_clk_mux,visa_mux_stage,visa_lane_mux,visa_lane_mux_slider}

configure_lint_tag_parameter -tag "70602" -parameter REPORT_OVERLAPPING_PATHS -value {no}

configure_lint_tag -enable -tag "70603"  -severity Error

configure_lint_tag_parameter -tag "70603" -parameter VISA_INPUT_PORT2_CHECKREGEXP -value {lane_in}

configure_lint_tag_parameter -tag "70603" -parameter VISA_MODULES_REGEXP -value {visa_(iomapper|unit|partition|repeater|central)_[0-9a-z_]+}

configure_lint_tag_parameter -tag "70603" -parameter VISA_MODULES_TO_IGNORE -value {visa_clk_mux,visa_mux_stage,visa_lane_mux,visa_lane_mux_slider}

configure_lint_tag_parameter -tag "70603" -parameter REPORT_OVERLAPPING_PATHS -value {yes}

configure_lint_tag -enable -tag "70604"  -severity Warning

configure_lint_tag_parameter -tag "70604" -parameter VISA_MODULES_REGEXP -value {visa_(iomapper|unit|partition|repeater|central)_[0-9a-z_]+}

configure_lint_tag_parameter -tag "70604" -parameter VISA_MODULES_TO_IGNORE -value {visa_clk_mux,visa_mux_stage,visa_lane_mux,visa_lane_mux_slider}

configure_lint_tag -enable -tag "70605"  -severity Info

configure_lint_tag_parameter -tag "70605" -parameter VISA_MODULES_REGEXP -value {visa_(iomapper|unit|partition|repeater|central)_[0-9a-z_]+}

configure_lint_tag_parameter -tag "70605" -parameter VISA_MODULES_TO_IGNORE -value {visa_clk_mux,visa_mux_stage,visa_lane_mux,visa_lane_mux_slider}

configure_lint_tag -enable -tag "70605_Info"  -severity Info

configure_lint_tag_parameter -tag "70605_Info" -parameter VISA_MODULES_REGEXP -value {visa_(iomapper|unit|partition|repeater|central)_[0-9a-z_]+}

configure_lint_tag_parameter -tag "70605_Info" -parameter VISA_MODULES_TO_IGNORE -value {visa_clk_mux,visa_mux_stage,visa_lane_mux,visa_lane_mux_slider}

configure_lint_tag -enable -tag "70606"  -severity Error

configure_lint_tag_parameter -tag "70606" -parameter VISA_MODULES_REGEXP -value {visa_(iomapper|unit|partition|repeater|central)_[0-9a-z_]+}

configure_lint_tag_parameter -tag "70606" -parameter VISA_MODULES_TO_IGNORE -value {visa_clk_mux,visa_mux_stage,visa_lane_mux,visa_lane_mux_slider}

configure_lint_tag_parameter -tag "70606" -parameter REPORT_OVERLAPPING_PATHS -value {yes}

configure_lint_tag -enable -tag "70607"  -severity Warning

configure_lint_tag_parameter -tag "70607" -parameter VISA_MODULES_REGEXP -value {visa_(iomapper|unit|partition|repeater|central)_[0-9a-z_]+}

configure_lint_tag_parameter -tag "70607" -parameter VISA_MODULES_TO_IGNORE -value {visa_clk_mux,visa_mux_stage,visa_lane_mux,visa_lane_mux_slider}

configure_lint_tag -enable -tag "70608"  -severity Error

configure_lint_tag_parameter -tag "70608" -parameter VISA_MODULES_REGEXP -value {visa_(iomapper|unit|partition|repeater|central)_[0-9a-z_]+}

configure_lint_tag_parameter -tag "70608" -parameter VISA_MODULES_TO_IGNORE -value {visa_clk_mux,visa_mux_stage,visa_lane_mux,visa_lane_mux_slider}

configure_lint_tag -enable -tag "70609"  -severity Error

configure_lint_tag_parameter -tag "70609" -parameter STAY_EMPTY_PORTNAME -value {.*xbar_out}

configure_lint_tag_parameter -tag "70609" -parameter VISA_MODULES_REGEXP -value {visa_(iomapper|unit|partition|repeater|central)_[0-9a-z_]+}

configure_lint_tag_parameter -tag "70609" -parameter VISA_MODULES_TO_IGNORE -value {visa_clk_mux,visa_mux_stage,visa_lane_mux,visa_lane_mux_slider}

configure_lint_tag -enable -tag "70610"  -severity Error

configure_lint_tag_parameter -tag "70610" -parameter VISA_MODULES_REGEXP -value {visa_(iomapper|unit|partition|repeater|central)_[0-9a-z_]+}

configure_lint_tag_parameter -tag "70610" -parameter VISA_MODULES_TO_IGNORE -value {visa_clk_mux,visa_mux_stage,visa_lane_mux,visa_lane_mux_slider}

configure_lint_tag -enable -tag "70611"  -severity Error

configure_lint_tag_parameter -tag "70611" -parameter VISA_MODULES_REGEXP -value {visa_(iomapper|unit|partition|repeater|central)_[0-9a-z_]+}

configure_lint_tag_parameter -tag "70611" -parameter VISA_MODULES_TO_IGNORE -value {visa_clk_mux,visa_mux_stage,visa_lane_mux,visa_lane_mux_slider}

configure_lint_tag -enable -tag "70612"  -severity Error

configure_lint_tag_parameter -tag "70612" -parameter VISA_CONFIG_INPUTPIN -value {serial_cfg_in.*}

configure_lint_tag_parameter -tag "70612" -parameter VISA_CONFIG_OUTPUTPIN -value {serial_cfg_out.*}

configure_lint_tag_parameter -tag "70612" -parameter VISA_MODULES_REGEXP -value {visa_(iomapper|unit|partition|repeater|central)_[0-9a-z_]+}

configure_lint_tag_parameter -tag "70612" -parameter VISA_MODULES_TO_IGNORE -value {visa_clk_mux,visa_mux_stage,visa_lane_mux,visa_lane_mux_slider}

configure_lint_tag_parameter -tag "70612" -parameter REPORT_OVERLAPPING_PATHS -value {yes}

configure_lint_tag -enable -tag "68801"  -severity Error

configure_lint_tag -enable -tag "InvalidAutoAssign"  -severity Error

configure_lint_tag -enable -tag "68803"  -severity Error

configure_lint_tag -enable -tag "68804"  -severity Error

configure_lint_tag -enable -tag "68805"  -severity Error

configure_lint_tag -enable -tag "00843"  -severity Error

configure_lint_tag -enable -tag "STARC05-2.2.2.2b"  -severity Error

configure_lint_tag -enable -tag "SensListRepeat-ML"  -severity Error

configure_lint_tag -enable -tag "STARC05-2.2.2.3a" -severity Error

configure_lint_tag_parameter -tag "STARC05-2.2.2.3a" -parameter STRICT -value {no}

configure_lint_tag -enable -tag "W164a_a"  -severity Error

configure_lint_tag -enable -tag "W164a_a" -type_id SG_LINT_W164A_A_VERILOG_ASSIGN_WIDTH_MISMATCH_DEADCODE -severity Warning

configure_lint_tag -enable -tag "W164a_a" -type_id SG_LINT_W164A_A_VERILOG_ASSIGN_WIDTH_MISMATCH_NBA_DEADCODE -severity Warning

configure_lint_tag -enable -tag "W164a_a" -type_id SG_LINT_W164A_A_VERILOG_CONCAT_ASSIGN_WIDTH_MISMATCH_DEADCODE -severity Warning

configure_lint_tag -enable -tag "W164a_a" -type_id SG_LINT_W164A_A_VERILOG_CONCAT_ASSIGN_WIDTH_MISMATCH_NBA_DEADCODE -severity Warning

configure_lint_tag -enable -tag "W164a_a" -type_id SG_LINT_W164A_A_VERILOG_PACKED_CONCAT_ASSIGN_WIDTH_MISMATCH_DEADCODE -severity Warning

configure_lint_tag -enable -tag "W164a_a" -type_id SG_LINT_W164A_A_VERILOG_PACKED_CONCAT_ASSIGN_WIDTH_MISMATCH_NBA_DEADCODE -severity Warning

configure_lint_tag -enable -tag "W164a_a" -type_id SG_LINT_W164A_A_VERILOG_W164_SS_DEADCODE -severity Warning

configure_lint_tag_parameter -tag "W164a_a" -parameter CHECK_NATURAL_WIDTH_OF_MULTIPLICATION -value {yes}

configure_lint_tag_parameter -tag "W164a_a" -parameter CHECK_STATIC_VALUE -value {yes}

configure_lint_tag_parameter -tag "W164a_a" -parameter CONCAT_WIDTH_NF -value {yes}

configure_lint_tag_parameter -tag "W164a_a" -parameter ENABLE_RTL_DEADCODE -value {yes}

configure_lint_tag_parameter -tag "W164a_a" -parameter HANDLE_LRM_PARAM_IN_SHIFT -value {yes}

configure_lint_tag_parameter -tag "W164a_a" -parameter HANDLE_SHIFT_OP -value {shift_both}

configure_lint_tag_parameter -tag "W164a_a" -parameter HANDLE_ZERO_PADDING -value {yes}

configure_lint_tag_parameter -tag "W164a_a" -parameter NOCHECKOVERFLOW -value {no}

configure_lint_tag_parameter -tag "W164a_a" -parameter PROCESS_COMPLETE_CONDOP -value {yes}

configure_lint_tag_parameter -tag "W164a_a" -parameter STRICT -value {yes}

configure_lint_tag_parameter -tag "W164a_a" -parameter TREAT_CONCAT_ASSIGN_SEPARATELY -value {yes}

configure_lint_tag_parameter -tag "W164a_a" -parameter REPORT_ONLY_FROM_ONE_HIERARCHY -value {yes}

configure_lint_tag -enable -tag "W164a_b"  -severity Warning

configure_lint_tag_parameter -tag "W164a_b" -parameter CHECK_COUNTER_ASSIGNMENT -value {yes}

configure_lint_tag_parameter -tag "W164a_b" -parameter CHECK_NATURAL_WIDTH_OF_MULTIPLICATION -value {yes}

configure_lint_tag_parameter -tag "W164a_b" -parameter CHECK_STATIC_VALUE -value {yes}

configure_lint_tag_parameter -tag "W164a_b" -parameter CONCAT_WIDTH_NF -value {yes}

configure_lint_tag_parameter -tag "W164a_b" -parameter ENABLE_RTL_DEADCODE -value {yes}

configure_lint_tag_parameter -tag "W164a_b" -parameter HANDLE_LRM_PARAM_IN_SHIFT -value {yes}

configure_lint_tag_parameter -tag "W164a_b" -parameter HANDLE_SHIFT_OP -value {shift_both}

configure_lint_tag_parameter -tag "W164a_b" -parameter HANDLE_ZERO_PADDING -value {yes}

configure_lint_tag_parameter -tag "W164a_b" -parameter NOCHECKOVERFLOW -value {no}

configure_lint_tag_parameter -tag "W164a_b" -parameter PROCESS_COMPLETE_CONDOP -value {yes}

configure_lint_tag_parameter -tag "W164a_b" -parameter STRICT -value {yes}

configure_lint_tag_parameter -tag "W164a_b" -parameter TREAT_CONCAT_ASSIGN_SEPARATELY -value {yes}

configure_lint_tag_parameter -tag "W164a_b" -parameter REPORT_ONLY_FROM_ONE_HIERARCHY -value {yes}

configure_lint_tag -enable -tag "W164b_a"  -severity Error

configure_lint_tag_parameter -tag "W164b_a" -parameter CHECK_NATURAL_WIDTH_OF_MULTIPLICATION -value {yes}

configure_lint_tag_parameter -tag "W164b_a" -parameter CHECK_STATIC_VALUE -value {yes}

configure_lint_tag_parameter -tag "W164b_a" -parameter CONCAT_WIDTH_NF -value {yes}

configure_lint_tag_parameter -tag "W164b_a" -parameter ENABLE_RTL_DEADCODE -value {yes}

configure_lint_tag_parameter -tag "W164b_a" -parameter HANDLE_LRM_PARAM_IN_SHIFT -value {yes}

configure_lint_tag_parameter -tag "W164b_a" -parameter HANDLE_SHIFT_OP -value {shift_left}

configure_lint_tag_parameter -tag "W164b_a" -parameter HANDLE_ZERO_PADDING -value {yes}

configure_lint_tag_parameter -tag "W164b_a" -parameter NOCHECKOVERFLOW -value {no}

configure_lint_tag_parameter -tag "W164b_a" -parameter PROCESS_COMPLETE_CONDOP -value {yes}

configure_lint_tag_parameter -tag "W164b_a" -parameter STRICT -value {yes}

configure_lint_tag_parameter -tag "W164b_a" -parameter TREAT_CONCAT_ASSIGN_SEPARATELY -value {yes}

configure_lint_tag_parameter -tag "W164b_a" -parameter REPORT_ONLY_FROM_ONE_HIERARCHY -value {yes}

configure_lint_tag -enable -tag "W164b_b"  -severity Warning

configure_lint_tag_parameter -tag "W164b_b" -parameter CHECK_NATURAL_WIDTH_OF_MULTIPLICATION -value {yes}

configure_lint_tag_parameter -tag "W164b_b" -parameter CHECK_STATIC_VALUE -value {yes}

configure_lint_tag_parameter -tag "W164b_b" -parameter ENABLE_RTL_DEADCODE -value {yes}

configure_lint_tag_parameter -tag "W164b_b" -parameter HANDLE_LRM_PARAM_IN_SHIFT -value {yes}

configure_lint_tag_parameter -tag "W164b_b" -parameter HANDLE_SHIFT_OP -value {shift_left}

configure_lint_tag_parameter -tag "W164b_b" -parameter HANDLE_ZERO_PADDING -value {yes}

configure_lint_tag_parameter -tag "W164b_b" -parameter NOCHECKOVERFLOW -value {no}

configure_lint_tag_parameter -tag "W164b_b" -parameter PROCESS_COMPLETE_CONDOP -value {yes}

configure_lint_tag_parameter -tag "W164b_b" -parameter STRICT -value {yes}

configure_lint_tag_parameter -tag "W164b_b" -parameter TREAT_CONCAT_ASSIGN_SEPARATELY -value {yes}

configure_lint_tag_parameter -tag "W164b_b" -parameter REPORT_ONLY_FROM_ONE_HIERARCHY -value {yes}

configure_lint_tag -enable -tag "W362a"  -severity Error

configure_lint_tag_parameter -tag "W362a" -parameter CHECK_STATIC_VALUE -value {yes}

configure_lint_tag_parameter -tag "W362a" -parameter ENABLE_RTL_DEADCODE -value {yes}

configure_lint_tag_parameter -tag "W362a" -parameter HANDLE_ZERO_PADDING -value {yes}

configure_lint_tag_parameter -tag "W362a" -parameter NOCHECKOVERFLOW -value {no}

configure_lint_tag_parameter -tag "W362a" -parameter STRICT -value {yes}

configure_lint_tag_parameter -tag "W362a" -parameter REPORT_ONLY_FROM_ONE_HIERARCHY -value {yes}

configure_lint_tag -enable -tag "W362b"  -severity Error

configure_lint_tag_parameter -tag "W362b" -parameter CHECK_STATIC_VALUE -value {yes}

configure_lint_tag_parameter -tag "W362b" -parameter ENABLE_RTL_DEADCODE -value {yes}

configure_lint_tag_parameter -tag "W362b" -parameter HANDLE_ZERO_PADDING -value {yes}

configure_lint_tag_parameter -tag "W362b" -parameter NOCHECKOVERFLOW -value {no}

configure_lint_tag_parameter -tag "W362b" -parameter STRICT -value {yes}

configure_lint_tag_parameter -tag "W362b" -parameter REPORT_ONLY_FROM_ONE_HIERARCHY -value {yes}

configure_lint_tag_parameter -tag "W110_a" -parameter HANDLE_SHIFT_OP -value {shift_both}

configure_lint_tag_parameter -tag "W110_a" -parameter HANDLE_ZERO_PADDING -value {yes}

configure_lint_tag_parameter -tag "W110_a" -parameter NOCHECKOVERFLOW -value {no}

configure_lint_tag -enable -tag "W110_b"  -severity Error

configure_lint_tag_parameter -tag "W110_b" -parameter HANDLE_SHIFT_OP -value {shift_both}

configure_lint_tag_parameter -tag "W110_b" -parameter HANDLE_ZERO_PADDING -value {yes}

configure_lint_tag_parameter -tag "W110_b" -parameter NOCHECKOVERFLOW -value {no}

configure_lint_tag -enable -tag "W348"  -severity Error

configure_lint_tag -enable -tag "STARC05-2.10.3.7" -severity Error

configure_lint_tag_parameter -tag "STARC05-2.10.3.7" -parameter IGNORE_BASED_WIDTH -value {yes}

configure_lint_tag_parameter -tag "STARC05-2.10.3.7" -parameter STRICT -value {no}

configure_lint_tag -enable -tag "STARC05-2.10.3.6" -severity Error

configure_lint_tag_parameter -tag "STARC05-2.10.3.6" -parameter BITWIDTH_BASEDCONST -value {32}

configure_lint_tag_parameter -tag "STARC05-2.10.3.6" -parameter STRICT -value {no}

configure_lint_tag -enable -tag "STARC05-1.4.3.1a" -severity Warning

configure_lint_tag_parameter -tag "STARC05-1.4.3.1a" -parameter IGNORECELLNAME -value {ctech_lib_clk_ffb,ctech_lib_clk_ffb_rstb,ctech_lib_clk_divider2,ctech_lib_clk_divider2_rstb}

configure_lint_tag_parameter -tag "STARC05-1.4.3.1a" -parameter IGNOREMODNAME -value {ctech_lib_clk.*}

configure_lint_tag -enable -tag "STARC05-1.4.3.1b" -severity Warning

configure_lint_tag_parameter -tag "STARC05-1.4.3.1b" -parameter IGNORECELLNAME -value {ctech_lib_clk_ffb,ctech_lib_clk_ffb_rstb,ctech_lib_clk_divider2,ctech_lib_clk_divider2_rstb}

configure_lint_tag_parameter -tag "STARC05-1.4.3.1b" -parameter IGNOREMODNAME -value {ctech_lib_clk.*}

configure_lint_tag -enable -tag "FlopClockUndriven" -severity Error

configure_lint_tag_parameter -tag "FlopClockUndriven" -parameter ALLVIOL -value {yes}

#configure_lint_tag -enable -tag "ClockEnableRace" -severity Warning

#configure_lint_tag_parameter -tag "ClockEnableRace" -parameter CHECKCOMBLOGIC -value {yes}

#configure_lint_tag_parameter -tag "ClockEnableRace" -parameter IGNORE_HANGING_FLOP -value {yes}

#configure_lint_tag_parameter -tag "ClockEnableRace" -parameter REPORT_COMMON_SOURCE -value {yes}

configure_lint_tag -enable -tag "sim_race07" -severity Error

configure_lint_tag -enable -tag "sim_race04" -severity Error

#configure_lint_tag -enable -tag "clock_used_as_data" -severity Warning

#configure_lint_tag_parameter -tag "clock_used_as_data" -parameter ALLVIOL -value {yes}

configure_lint_tag -enable -tag "70094"  -severity Error

configure_lint_tag_parameter -tag "70094" -parameter CHECKSEQPHASE -value {yes}

configure_lint_tag -enable -tag "W193"  -severity Error

configure_lint_tag_parameter -tag "W193" -parameter REPORT_IF_BLOCKS_ONLY -value {yes}

configure_lint_tag -enable -tag "IfWithoutElse-ML" -severity Error

configure_lint_tag_parameter -tag "IfWithoutElse-ML" -parameter IGNOREREALLATCH -value {yes}

configure_lint_tag_parameter -tag "IfWithoutElse-ML" -parameter IGNORE_LOOP_INDEX -value {yes}

configure_lint_tag_parameter -tag "IfWithoutElse-ML" -parameter IGNORE_STATIC_CONDITION -value {yes}

configure_lint_tag -enable -tag "AlwaysFalseTrueCond-ML" -type_id SG_MORELINT_ALWAYSFALSETRUECOND_ML_VERILOG_ALWAYSFALSETRUECOND_ML_VE -severity Error

configure_lint_tag -enable -tag "AlwaysFalseTrueCond-ML" -type_id SG_MORELINT_ALWAYSFALSETRUECOND_ML_VERILOG_ALWAYSFALSETRUECOND_ML_VE_1 -severity Warning

configure_lint_tag_parameter -tag "AlwaysFalseTrueCond-ML" -parameter EVALUATE_FOR_LOOP_INDEX -value {yes}

configure_lint_tag_parameter -tag "AlwaysFalseTrueCond-ML" -parameter IGNORE_COND_HAVING_IDENTIFIER -value {yes}

configure_lint_tag_parameter -tag "AlwaysFalseTrueCond-ML" -parameter REPORT_ALWAYS_COND -value {false}

configure_lint_tag_parameter -tag "AlwaysFalseTrueCond-ML" -parameter REPORT_LESS_SEVERITY -value {yes}

configure_lint_tag -enable -tag "W527"  -severity Warning

configure_lint_tag -enable -tag "60000_a"  -severity Error

configure_lint_tag_parameter -tag "60000_a" -parameter CHECK_OUTPUT_PORTS -value {yes}

#configure_lint_tag_parameter -tag "60000_a" -parameter IGNORE_FUNCTION_INITIALIZATION -value {yes}

configure_lint_tag -enable -tag "NullPort-ML" -severity Error

configure_lint_tag -enable -tag "W192"  -severity Warning

configure_lint_tag -enable -tag "2218"  -severity Error

configure_lint_tag -enable -tag "50520"  -severity Error

configure_lint_tag_parameter -tag "50520" -parameter IFDEFS -value {SVA_OFF,VCSSIM,INST_ON,DC,SYNTHESIS,VCS,FGPA,QUICKCOV_INST_ENABLE,QC_COVER_ENABLE,MANUAL_XPROP,ASSERT_OFF,ASSERT_ON,SIMULATION,XPROPAGATION,HIPS_PS_RESOLUTION,PULSE_WIDTH_OFF,no_unit_delay,VCS_BUG,LINTRA_BUG,SPYGLASS_BUG,QUESTACDC_BUG,DC_BUG,VELOCE_BUG,ZEBU_BUG,FISHTAIL_BUG,FEV_BUG,SYNPLICITY_BUG,POWERARTIST_BUG,VERDI_BUG,JASPERGOLD_BUG,EMULATION,NO_PWR_PINS,JEM_STANDALONE,JEM_USE_DPI_ENABLING,SLA_RTL_TLM_PORTS_OFF,SLA_RTL_TLM_MONITOR_INST_OFF,SLA_EXTERNAL_RTL_TLM_IMPL,JEM_TLM_PORTS_OFF,JEM_NO_CDT_DPI,JEM_NO_DPI_IN_INITIAL,JEM_INIT_CLK,JEM_INIT_CLK_EDGE,JEM_TLM_PORT_ENABLE_INIT_STATE,JEM_EMILATION_ZSE,JEM_COV_SAMPLE_CLK,QUICKCOV_JEM_COLLECTION,OVM,UVM,SNPS201412B}

configure_lint_tag -enable -tag "52544"  -severity Error

configure_lint_tag -enable -tag "ExprParen" -severity Error

configure_lint_tag_parameter -tag "ExprParen" -parameter ALLOWEDOPPRECEDENCE -value {(a + b * c)(a - b * c)(a + b / c)(a - b / c)(a - b + c)(a * b / c)(a - b - c)(a + b + c)(a * b * c)(a / b/ c)(!a)(~a)(a & b & c)(a | b | c)}

configure_lint_tag_parameter -tag "ExprParen" -parameter DISPLAYEXPRESSION -value {yes}

configure_lint_tag_parameter -tag "ExprParen" -parameter IGNORE_MODULE -value {1}

configure_lint_tag -enable -tag "CheckExprCast" -severity Error

configure_lint_tag -enable -tag "SignedUnsignedExpr-ML" -severity Error

configure_lint_tag_parameter -tag "SignedUnsignedExpr-ML" -parameter IGNORE_STATIC_EXPRS -value {yes}

configure_lint_tag_parameter -tag "SignedUnsignedExpr-ML" -parameter IGNOREFORINDEX -value {yes}

configure_lint_tag_parameter -tag "SignedUnsignedExpr-ML" -parameter STRICT -value {no}

configure_lint_tag -enable -tag "W129"  -severity Error

configure_lint_tag -enable -tag "W188"  -severity Error

configure_lint_tag -enable -tag "W504"  -severity Error

configure_lint_tag_parameter -tag "W504" -parameter STRICT -value {yes}

configure_lint_tag -enable -tag "InvalidMacroCall-ML" -severity Error

configure_lint_tag -enable -tag "60047"  -severity Error

configure_lint_tag -enable -tag "check_forloop_index" -severity Info

configure_lint_tag -enable -tag "60118"  -severity Error

configure_lint_tag -enable -tag "0209"  -severity Error

configure_lint_tag -enable -tag "STARC05-2.8.1.5" -severity Error

configure_lint_tag -enable -tag "STARC05-2.8.5.1" -severity Error

configure_lint_tag -enable -tag "W171"  -severity Warning

configure_lint_tag_parameter -tag "W171" -parameter IGNORE_CONST_SELECTOR -value {yes}

configure_lint_tag -enable -tag "DuplicateCase-ML" -severity Error

configure_lint_tag_parameter -tag "DuplicateCase-ML" -parameter IGNORE_PRIORITY_CASE -value {yes}

configure_lint_tag -enable -tag "STARC05-2.8.3.5" -severity Warning

configure_lint_tag -enable -tag "UseSVAlways-ML" -severity Error

configure_lint_tag_parameter -tag "UseSVAlways-ML" -parameter STRICT -value {yes}

configure_lint_tag -enable -tag "2216"  -severity Error

configure_lint_tag_parameter -tag "2216" -parameter VIOLATE_SAME_SIGNAL_ONLY -value {yes}

configure_lint_tag -enable -tag "RptNegEdgeFF-ML" -severity Info

configure_lint_tag -enable -tag "UnInitializedReset-ML" -severity Error

configure_lint_tag_parameter -tag "UnInitializedReset-ML" -parameter IGNORE_SYNC_RESET -value {yes}

configure_lint_tag -enable -tag "RegInput-ML" -severity Warning

configure_lint_tag_parameter -tag "RegInput-ML" -parameter DEPTH_ML -value {1}

configure_lint_tag -enable -tag "RegOutputs" -severity Warning

configure_lint_tag_parameter -tag "RegOutputs" -parameter REPORTUNDRIVENOUT -value {no}

configure_lint_tag -enable -tag "AvoidAsync" -severity Info

configure_lint_tag -enable -tag "02084"  -severity Error

configure_lint_tag -enable -tag "0536"  -severity Error

configure_lint_tag -enable -tag "STARC05-2.2.3.1" -severity Error

configure_lint_tag -enable -tag "0563"  -severity Error

configure_lint_tag -enable -tag "60041"  -severity Error

configure_lint_tag -enable -tag "60086"  -severity Error

configure_lint_tag -enable -tag "60137"  -severity Error

configure_lint_tag -enable -tag "W372"  -severity Error

configure_lint_tag_parameter -tag "W372" -parameter REPORT_CAST -value {yes}

configure_lint_tag -enable -tag "UnsetProcedureRecord" -severity Warning

configure_lint_tag -enable -tag "50002"  -severity Error

configure_lint_tag_parameter -tag "50002" -parameter CHECK_PARTIAL_CASE_CASEZ -value {yes}

configure_lint_tag_parameter -tag "50002" -parameter IGNORE_X_INCASE_CASEZ -value {yes}

configure_lint_tag -enable -tag "DisallowXInCaseZ-ML" -severity Error

configure_lint_tag -enable -tag "OneModule-ML" -severity Error

configure_lint_tag_parameter -tag "OneModule-ML" -parameter IGNOREFILES -value {(.*ctech.*|.*LVISION.*|.*_map\.sv$|.*mbist.*|.*\.lib$)}

configure_lint_tag -enable -tag "STARC05-1.1.1.1" -severity Error

configure_lint_tag_parameter -tag "STARC05-1.1.1.1" -parameter IGNORE_FILE_PATH -value {yes}

configure_lint_tag_parameter -tag "STARC05-1.1.1.1" -parameter IGNORE_FILE_WITH_MULTIPLE_MODULES -value {yes}

configure_lint_tag_parameter -tag "STARC05-1.1.1.1" -parameter STARC_FILE_EXT_VLOG -value {.v,.vs,.sv,.xfsm.vs}

configure_lint_tag -enable -tag "FileHdr" -severity Warning

configure_lint_tag_parameter -tag "FileHdr" -parameter FILE_HDR_IGNORE_PATH -value {.*src\/rtl\/tessent\/.*_(wrapper|uscg)_tessent.*\.v}

configure_lint_tag_parameter -tag "FileHdr" -parameter IGNORE_FILES_WITH_STOPPED_MODULES -value {yes}

configure_lint_tag -enable -tag "ModuleInIncludeFile" -severity Warning

configure_lint_tag -enable -tag "ArrayIndex" -severity Error

configure_lint_tag_parameter -tag "ArrayIndex" -parameter CHECKALLDIMENSION -value {yes}

configure_lint_tag_parameter -tag "ArrayIndex" -parameter STRICT -value {no}

configure_lint_tag -enable -tag "W468"  -severity Warning

# SG rule SYNTH_5130 is mapped to ImproperRangeIndex-ML
# SG rule SYNTH_5255 is also partially mapped to rule ImproperRangeIndex-ML,
# therefore uprevving it to Error with the below exception for ceratin type_ids

configure_lint_tag -enable -tag "ImproperRangeIndex-ML" -severity Warning

configure_lint_tag -enable -tag "ImproperRangeIndex-ML" -type_id SG_MORELINT_IMPROPERRANGEINDEX_ML_VERILOG_IMPROPERRANGEINDEX_ML_STATICBITSELECT -severity Warning

configure_lint_tag -enable -tag "ImproperRangeIndex-ML" -type_id SG_MORELINT_IMPROPERRANGEINDEX_ML_VERILOG_IMPROPERRANGEINDEX_ML_STATICPARTSELECT -severity Warning

configure_lint_tag_parameter -tag "ImproperRangeIndex-ML" -parameter REPORT_LOOP_VAR_EXPR -value {yes}

configure_lint_tag_parameter -tag "ImproperRangeIndex-ML" -parameter NOCHECKOVERFLOW -value {no}

configure_lint_tag_parameter -tag "ImproperRangeIndex-ML" -parameter REPORT_STATIC_INDEXES -value {yes}

configure_lint_tag_parameter -tag "ImproperRangeIndex-ML" -parameter REPORT_ONLY_FROM_ONE_HIERARCHY -value {yes}

configure_lint_tag -enable -tag "W576"  -severity Error

configure_lint_tag -enable -tag "ParamReDefined" -severity Warning

configure_lint_tag_parameter -tag "ParamReDefined" -parameter IGNORE_MULTIPLE_PACKAGE_IMPORT -value {yes}

configure_lint_tag_parameter -tag "ParamReDefined" -parameter IGNORE_PARAMS_WITH_SAME_VALUE -value {yes}

configure_lint_tag -enable -tag "W154"  -severity Error

configure_lint_tag_parameter -tag "W154" -parameter GROUP_BY_MODULE -value {yes}

configure_lint_tag_parameter -tag "W154" -parameter IGNORE_FILES_REGEXP -value {.*collage.*|.*defacto.*}

configure_lint_tag_parameter -tag "W154" -parameter REPORT_PORT_NET -value {yes}

configure_lint_tag -enable -tag "2083"  -severity Warning

configure_lint_tag -enable -tag "UnusedTypedef" -severity Warning

configure_lint_tag -enable -tag "W175"  -severity Warning

configure_lint_tag_parameter -tag "W175" -parameter REPORT_GLOBAL_PARAM -value {yes}

configure_lint_tag -enable -tag "60175"  -severity Error

configure_lint_tag -enable -tag "60044"  -severity Warning

configure_lint_tag -enable -tag "0301"  -severity Warning

configure_lint_tag -enable -tag "60130"  -severity Error


configure_lint_tag -enable -tag "60159"  -severity Error

#configure_lint_tag_parameter -tag "60159" -parameter DEFINITION_TYPES -value {functions,tasks,typedefs,parameters,local_parameters,import_statments}

configure_lint_tag -enable -tag "ProhibitedDataTypes-ML" -severity Error

configure_lint_tag_parameter -tag "ProhibitedDataTypes-ML" -parameter PROHIBITED_DATA_TYPES -value {logic,bit}

configure_lint_tag -enable -tag "CheckExplicitImports" -severity Warning

configure_lint_tag -enable -tag "UseParamInsteadDefine-ML" -severity Error

configure_lint_tag -enable -tag "W259"  -severity Error

configure_lint_tag -enable -tag "DetectInvalidSignedAssignment-ML" -severity Info

configure_lint_tag -enable -tag "DetectUnderAndOverFlows-ML" -type_id SG_MORELINT_DETECTUNDERANDOVERFLOWS_ML_VERILOG_DETECTUNDERANDOVERFLOWS_ML_MSG_WARNING -severity Error

configure_lint_tag -enable -tag "DetectUnderAndOverFlows-ML" -type_id SG_MORELINT_DETECTUNDERANDOVERFLOWS_ML_VERILOG_DETECTUNDERANDOVERFLOWS_ML_MSG_NC_TRUNCATION -severity Warning

configure_lint_tag -enable -tag "DetectUnderAndOverFlows-ML" -type_id SG_MORELINT_DETECTUNDERANDOVERFLOWS_ML_VERILOG_DETECTUNDERANDOVERFLOWS_ML_MSG_INFO -severity Warning

configure_lint_tag_parameter -tag "DetectUnderAndOverFlows-ML" -parameter CHECK_TYPE_CAST -value {yes}

configure_lint_tag_parameter -tag "DetectUnderAndOverFlows-ML" -parameter NOCHECKOVERFLOW -value {no}

configure_lint_tag_parameter -tag "DetectUnderAndOverFlows-ML" -parameter HANDLE_SHIFT_OP -value {shift_left}

configure_lint_tag_parameter -tag "DetectUnderAndOverFlows-ML" -parameter DIFFERENTIATE_NESTED_CAST -value {yes}

configure_lint_tag -enable -tag "UseParamInsteadDefine-ML" -severity Error

configure_lint_tag -enable -tag "IfOverlap-ML" -severity Error

configure_lint_tag -enable -tag "UniqueIfMissingCond-ML" -severity Error -formal

configure_lint_tag -enable -tag "CheckGuardMacro" -severity Error

configure_lint_tag_parameter -tag "CheckGuardMacro" -parameter CHECK_FILE_NAME -value {yes}

configure_lint_tag -enable -tag "AvoidMultiDimParam-ML" -severity Error

# Rules for testing purposes ONLY

#configure_lint_tag -enable -tag DefaultState -severity Warning

#configure_lint_tag_parameter -tag "DefaultState" -parameter CHECK_ONLY_CASE_STMT -value {yes}

set_app_var sh_continue_on_error $saved_sh_continue_on_error

#################### Builtin Rule Configurations ####################

set saved_sh_continue_on_error [get_app_var sh_continue_on_error]

set_app_var sh_continue_on_error true

#Rule configuration for SG rule : INFO_1010

configure_tag -tag VC_INFO_UDP_TRANSLATE -enable -severity Error

#Rule configuration for SG rule : SGDCWRN_127

configure_tag -tag VC_PRAGMA_INCORRECT_RULE -disable

#Rule configuration for SG rule : SGDC_waive35

configure_tag -tag VC_WAIVER_BLOCK_NOT_FOUND -severity Warning

# blanket waivers are NOT allowed : SGDC_waive39

configure_tag -tag {VC_WAIVER_ONLY_TAG_GIVEN} -severity {Error}

#Rule configuration for SG rule : SYNTH_1082

configure_tag -tag OOECAIAB -enable -severity Error

#Rule configuration for SG rule : SYNTH_1111

configure_tag -tag SM_URT -enable -severity Error

#Rule configuration for SG rule : SYNTH_12605

configure_tag -tag { SM_FCNF SM_PCNP SM_PNP SM_TUFC } -enable -severity Warning

#Rule configuration for SG rule : SYNTH_12608

configure_tag -tag { SM_MCAL SM_MLAC SM_MLAFF } -enable -severity Error

#Rule configuration for SG rule : SYNTH_132

configure_tag -tag VC_SYNTH_HIER_REF -enable -severity Error

#Rule configuration for SG rule : SYNTH_196

configure_tag -tag VC_SYNTH_TASK_EVENT -enable -severity Error

#Rule configuration for SG rule : SYNTH_5064

configure_tag -tag VC_SYNTH_STMT_IGNORED -disable

#Rule configuration for SG rule : SYNTH_5142

configure_tag -tag VC_SYNTH_SPECIFY_UNSUPP -enable -severity Error

#Rule configuration for SG rule : SYNTH_5143

configure_tag -tag SM_IGN_INITIAL -disable

#Rule configuration for SG rule : WRN_1036

configure_tag -tag VC_WRN_EVENT_VALID -enable -severity Error

#Rule configuration for SG rule : WRN_1041

configure_tag -tag VC_WRN_UNDERSCORE_IGNORED -severity Error

#Rule configuration for SG rule : WRN_1042

configure_tag -tag IIPCNDO -enable -severity Error

#Rule configuration for SG rule : WRN_1453

configure_tag -tag VC_WRN_PORT_INVALID -enable -severity Error

#Rule configuration for SG rule : WRN_1469

configure_tag -tag ENUMASSIGN -enable -severity Warning

#Rule configuration for SG rule : WRN_26

configure_tag -tag TMR -enable -severity Error

#Rule configuration for SG rule : WRN_32

configure_tag -tag IICD -severity Warning

#Rule configuration for SG rule : WRN_54 and WRN_1464

configure_tag -tag AOUP -enable -severity Error

#Rule configuration for SG rule : WRN_70

configure_tag -tag SAGB -enable -severity Error

configure_tag -tag  OPD -enable -severity Info

#Rule configuration for SG rule: WRN_1467

configure_tag -tag DPIMI -enable -severity Error

# Rule configuration for SG rule: STX_VE_361

#configure_tag -tag IUAO -enable -severity Fatal

configure_tag -tag IBLHS-NT -enable -severity Fatal

# Rule configuration for SG rule: STX_VE_467

configure_tag -tag ICTA -enable -severity Fatal

# Rule configuration for SG rule: STX_VE_462

configure_tag -tag SV-USAC -enable -severity Fatal

# Rule configuration for SG rule: WRN_40

configure_tag -tag IPDW -enable -severity Fatal

# Rule configuration for SG rule: WRN_1471

configure_tag -tag USL -enable -severity Error

#Rule configuration for SG rule : SYNTH_89

configure_tag -tag VC_SYNTH_INITIAL_IGNORED -enable -severity Error

set_app_var sh_continue_on_error $saved_sh_continue_on_error

#################### Builtin Rule Configurations End
####################

#configure_lint_setup  -j 4
