/* Copyright 2018 ETH Zurich and University of Bologna.
 * Copyright and related rights are licensed under the Solderpad Hardware
 * License, Version 0.51 (the “License”); you may not use this file except in
 * compliance with the License.  You may obtain a copy of the License at
 * http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
 * or agreed to in writing, software, hardware and materials distributed under
 * this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * File:   dm_pkg.sv
 * Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
 * Date:   30.6.2018
 *
 * Description: Debug-module package, contains common system definitions.
 *
 */

package dm;
  localparam logic [3:0] DbgVersion013 = 4'h2;
  // size of program buffer in junks of 32-bit words
  localparam logic [4:0] ProgBufSize   = 5'h8;

  // amount of data count registers implemented
  localparam logic [3:0] DataCount     = 4'h2;

  // address to which a hart should jump when it was requested to halt
  localparam logic [63:0] HaltAddress = 64'h800;
  localparam logic [63:0] ResumeAddress = HaltAddress + 8;
  localparam logic [63:0] ExceptionAddress = HaltAddress + 16;

  // address where data0-15 is shadowed or if shadowed in a CSR
  // address of the first CSR used for shadowing the data
  localparam logic [11:0] DataAddr = 12'h380; // we are aligned with Rocket here

  typedef enum logic [2:0] {
    CmdErrNone, CmdErrBusy, CmdErrNotSupported,
    CmdErrorException, CmdErrorHaltResume,
    CmdErrorBus, CmdErrorOther = 7
  } cmderr_e;

  typedef struct packed {
    logic [31:29] zero3;
    logic [28:24] progbufsize;
    logic [23:13] zero2;
    logic         busy;
    logic         zero1;
    cmderr_e      cmderr;
    logic [7:4]   zero0;
    logic [3:0]   datacount;
  } abstractcs_t;

  typedef enum logic [7:0] {
    AccessRegister = 8'h0,
    QuickAccess    = 8'h1,
    AccessMemory   = 8'h2
  } cmd_e;

  typedef struct packed {
    cmd_e        cmdtype;
    logic [23:0] control;
  } command_t;

  typedef struct packed {
    logic [31:16] autoexecprogbuf;
    logic [15:12] zero0;
    logic [11:0]  autoexecdata;
  } abstractauto_t;

  typedef struct packed {
    logic         zero1;
    logic [22:20] aarsize;
    logic         aarpostincrement;
    logic         postexec;
    logic         transfer;
    logic         write;
    logic [15:0]  regno;
  } ac_ar_cmd_t;

  // DTM
  typedef enum logic [1:0] {
    DTM_NOP   = 2'h0,
    DTM_READ  = 2'h1,
    DTM_WRITE = 2'h2
  } dtm_op_e;

  typedef enum logic [1:0] {
    DTM_SUCCESS = 2'h0,
    DTM_ERR     = 2'h2,
    DTM_BUSY    = 2'h3
  } dtm_op_status_e;

  typedef struct packed {
    logic [31:29] sbversion;
    logic [28:23] zero0;
    logic         sbbusyerror;
    logic         sbbusy;
    logic         sbreadonaddr;
    logic [19:17] sbaccess;
    logic         sbautoincrement;
    logic         sbreadondata;
    logic [14:12] sberror;
    logic [11:5]  sbasize;
    logic         sbaccess128;
    logic         sbaccess64;
    logic         sbaccess32;
    logic         sbaccess16;
    logic         sbaccess8;
  } sbcs_t;

  typedef struct packed {
    logic [16:0]  addr;
    dtm_op_e     op;
    logic [31:0] data;
  } dmi_req_t;

  typedef struct packed  {
    logic [31:0] data;
    logic [1:0]  resp;
  } dmi_resp_t;

  typedef struct packed {
    logic [31:18] zero1;
    logic         dmihardreset;
    logic         dmireset;
    logic         zero0;
    logic [14:12] idle;
    logic [11:10] dmistat;
    logic [9:4]   abits;
    logic [3:0]   version;
  } dtmcs_t;

endpackage : dm
