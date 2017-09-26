# THGEM-Camera-DAQ

This is the data acquistion (DAQ) firmware for a two-dimensional THGEM based camera that uses the delay-line method for two-dimensional readout. The DAQ system uses a field programmable gate array (FPGA) as the main data processor and a time-to-digital (TDC) mezzanine card for making time measurements. We developed the TDC mezzanine card around the Acam TDC-GPX ASIC and it features four independent stop channels referenced to a common start, a typical timing resolution of 81 ps, and a 17-bit measurement range, and is compliant with the VITA 57.1 standard. For the FPGA we use the Xilinx SP601 development kit which features a single Spartan 6 FPGA, 128 MB of DDR2 memory, and a serial USB interface for communication. Output images consist of 1024 x 1024 square pixels, where each pixel has a 32-bit depth and corresponds to a time difference of 162 ps relative to its neighbours. When configured for a 250 ns acquisition window, the DAQ can resolve periodic event rates up to 1.8 MHz without any loses and will report a maximum event rate of 0.611 MHz for events whose arrival times follow Poisson statistics. The integral and differential nonlinearities have also been measured and are better than 0.1% and 1.5%, respectively.

If you use this software, please cite:

    @article{hanu2015data,
      title={A data acquisition system for two-dimensional position sensitive micropattern gas detectors with delay-line readout},
      author={Hanu, AR and Prestwich, WV and Byun, SH},
      journal={Nuclear Instruments and Methods in Physics Research Section A: Accelerators, Spectrometers, Detectors and Associated Equipment},
      volume={780},
      pages={33--39},
      year={2015},
      publisher={Elsevier}
    }

  
# GUI Screenshot
![GUI screenshot](https://github.com/AndreiHanu/THGEM-Camera-DAQ/blob/master/GUI%20Screenshot.jpg)
