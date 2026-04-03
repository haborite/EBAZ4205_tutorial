# ============================================
# Vivado Project Setup Script (setup.tcl)
# Variable-driven version
# ============================================

# -------------------------------
# 外部から上書き可能な変数
# -------------------------------
if {![info exists proj_name]} { set proj_name "proj_zynq" }
if {![info exists proj_dir]}  { set proj_dir "./ws/${proj_name}" }
if {![info exists part_name]} { set part_name "xc7z010clg400-1" }
if {![info exists bd_tcl]}    { set bd_tcl "./bd.tcl" }

# -------------------------------
# 表示
# -------------------------------
puts "============================================"
puts " Project Name : $proj_name"
puts " Project Dir  : $proj_dir"
puts " Part         : $part_name"
puts " BD Tcl       : $bd_tcl"
puts "============================================"

# -------------------------------
# プロジェクト作成
# -------------------------------
create_project ${proj_name} ${proj_dir} -part ${part_name} -force

set_property target_language Verilog [current_project]

# ============================================
# ソースファイル追加
# ============================================

# HDL
set hdl_files [glob -nocomplain ./*.v ./*.sv]
if {[llength $hdl_files] > 0} {
    add_files -fileset sources_1 -copy_to ${proj_dir}/sources_1 $hdl_files
}

# XDC
set xdc_files [glob -nocomplain ./*.xdc]
if {[llength $xdc_files] > 0} {
    add_files -fileset constrs_1 -copy_to ${proj_dir}/constrs_1 $xdc_files
}


# ============================================
# Block Design 読み込み ＋ Wrapper自動生成
# ============================================

if {[file exists $bd_tcl]} {

    puts "INFO: Importing Block Design from $bd_tcl"

    # BD生成
    source $bd_tcl

    # BD名取得（安全版）
    set bd_list [get_bd_designs]
    if {[llength $bd_list] == 0} {
        error "No Block Design found after sourcing $bd_tcl"
    }

    set bd_name [lindex $bd_list 0]
    puts "INFO: Detected BD = $bd_name"

    # ----------------------------------------
    # Wrapper自動生成（ここが重要）
    # ----------------------------------------
    make_wrapper -files [get_files ${bd_name}.bd] -top -import

    # wrapperファイル取得
    set wrapper_file [get_files -filter "NAME =~ *${bd_name}_wrapper.v"]

    if {[llength $wrapper_file] == 0} {
        error "Wrapper file not found"
    }

    puts "INFO: Wrapper = $wrapper_file"

    # Top指定
    set_property top ${bd_name}_wrapper [current_fileset]
}

# ============================================
# コンパイル順更新
# ============================================

update_compile_order -fileset sources_1

# ============================================
# Run
# ============================================

# launch_runs synth_1 -jobs 4
# wait_on_run synth_1

# launch_runs impl_1 -to_step write_bitstream -jobs 4
# wait_on_run impl_1

# ============================================
puts "============================================"
puts " Project setup completed"
puts "============================================"
