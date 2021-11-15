# ProNoC

## Project Summary

Prototype-network-on-chip (ProNoC) is an EDA tool that facilitates prototyping of custom heterogeneous NoC-based many-core-SoC (MCSoC). ProNoC is enhanced using a parameterizable virtual channel based low-latency NoC that is optimized for FPGA implementation. Moreover, ProNoC can also be used as a custom Wishbone bus based SoC generator (SoC without NoC) using available Intellectual Properties (IPs) in ProNoC library. The ProNoC IP library can be easily extended to support more IPs.

![abstract](https://opencores.org/usercontent/img/1483515008)

## ProNoC GUI MCSoC Generator

Writing the whole RTL code of a complex heterogeneous MCSoC manually can be time-consuming and error-prone due to the huge number of possible configurations as well as high similarity among sub-components code portions. In order to facilitate the design of such complex systems, ProNoC, an open-source EDA tool that generates the complete heterogeneous customized NoC-based MCSoC RTL code is developed. The design effort increases when developing a heterogeneous MCSoC as each processing tile must be designed separately. To ease and speed up the development of such platform, a graphical user interface (GUI) is developed to generate a custom NoC-based MCSoC. The ProNoC GUI is written with Perl programming language and GTK2 library. ProNoC consists of four main windows corresponding to each layer in MCSoC design as follow.

1.  **Interface Generator:** The components interconnection is facilitated by defining the interface. Interface is the combination of several ports that provide specific functionality.
2.  **IP Generator:** The IP generator facilitates the process of making a library for each IP. An IP can either be a processor or a peripheral device such as memory, timer, bus or an interrupt controller. The IP generator reads the Verilog file containing the top-level module of the IP and user can define the number of interfaces and map them to the IP ports. 
3.  **Processing Tile Generator:** The processing tile (PT) generator contains the list of all IPs that can be connected to each other using available defined interfaces. This integration tool provides some facilities such as automatic generation of interconnect logic and automatic Wishbone address setting. It also provides graphical interface for setting different IP parameters. 
4.  **NoC-based MCSoC Generator:** The MCSoC generator facilitates the generation of a heterogeneous NoC-based MCSoC by providing GUI interface for setting the NoC’s and PTs’ parameters. It checks all processing tiles which have been previously generated using the PT generator and lists all the tiles containing the NI to connect to the NoC

![mpsoc generator snapshot](https://opencores.org/usercontent/img/1483518851)

## NoC Specification

ProNoC presents an FPGA-optimized NoC-based MCSoC with ASIC-based NoC functionalities. The NoC specifications are as follow:

-   **Wormhole packet switching flow-control**: Wormhole allows storing of different flits of the same packet in several routers along the path and requires low buffer.
-   **Virtual Channel(VC)**: ProNoC supports parameterizable number of VCs. All VCs that are located in the same input port of the router share one BRAM memory. 
-   **Combined VC/switch allocator**: combined allocator allows simultaneous allocation of VC and switch stages in the same clock cycle to reduce the router latency and cost.
-   **Non-atomic or atomic VC reallocation**: In atomic VC reallocation, a free VC can be reallocated only when it is empty. whereas in non-atomic VC reallocation a non-empty VC can be reallocated once it receives the tail flit.  
-   **NoC topology**: Currently ProNoC supports foloowing topologies: Mesh, Torus, Ring, Line,Fattree,BinTree,Star and user defined custom topologies
-   **Different routing algorithm**: ProNoC supports deterministic (DoR), partial adaptive (turn models and odd-even) and fully adaptive routing. 
-   **Router pipeline stages**: ProNoC NoC router has two pipeline stages. In the first stage three processes of look-ahead route computation, VC allocation and SW allocation are done in parallel. The second stage is switch traversal. ProNoC can also be configured with a static strength allocator (SSA), which allows packets traversing to the same direction pass NoC router withing 1-clk latency.  Moreover, enabling SMART features allows a flit going in the same direction bypasses several routers in a single cycle.
-    **Hard-built QoS**: provide Equality-of-Service (EoS) or Differential-Service (DS) as subsets of QoS for injected packets based on initial wait.


## ProNoC NoC Simulator
The ProNoC NoC is developed in RTL using SystemVerilog HDL and it can be simulated using Verilator simulator. The ProNoC simulator provides the graphical user interface (GUI) for simulating different NoC configuration under different type traffic patterns:
- Synthetic
- Task-based
- Trace-based
![](https://cdn.opencores.org/usercontent/eb8278cdf63a64a7079342e277966f5346576e6107c28fa954e0fd744617d1de.png)

## How to Cite
If you found ProNoC useful please cite some of the following references in your publications:

1. Alireza Monemi, et al. "_PIugSMART: a pluggable open-source module to implement multihop bypass in networks-on-chip._" Proceedings of the 15th IEEE/ACM International Symposium on Networks-on-Chip. 2021.
2. A Monemi, F Khunjush, M Palesi, H Sarbazi-Azad, "_An Enhanced Dynamic Weighted Incremental Technique for QoS Support in NoC_" ACM Transactions on Parallel Computing (TOPC),  pagesp 1–31,2020
3.  Alireza Monemi, Jia Wei Tang, Maurizio Palesi, Muhammad N. Marsono, "_ProNoC: A low latency network-on-chip based many-core system-on-chip prototyping platform_", Microprocessors and Microsystems, Volume 54, October 2017, Pages 60-74.
4.  Alireza Monemi, Chia Yee Ooi, Maurizio Palesi, and Muhammad Nadzir Marsono. "_Low latency network-on-chip router using static straight allocator_". In Proceedings of 3rd International Conference on Information Technology, Computer and Electrical Engineering, ICITACEE’16. IEEE, 2016.
5.  Alireza Monemi, Chia Yee Ooi, Muhammad Nadzir Marsono, and Maurizio Palesi. "_Improved flow control for minimal fully adaptive routing in 2D mesh NoC_". In Proceedings of the 9th International Workshop on Network on Chip Architectures, NoCArc’16, pages 9–14. ACM, 2016.
6.  Alireza Monemi, Chia Yee Ooi, and Muhammad Nadzir Marsono. "_Low latency network-__on-chip router microarchitecture using request masking technique_". International Journal of Reconfigurable Computing, 2015:2, 2015.

## Additional Documentation
For more information and tutorials, please check following directories:
-  "trunk/doc"

## Bug reporting
For any bug  or feedback reporting please contact me via <alirezamonemi@opencores.org>
