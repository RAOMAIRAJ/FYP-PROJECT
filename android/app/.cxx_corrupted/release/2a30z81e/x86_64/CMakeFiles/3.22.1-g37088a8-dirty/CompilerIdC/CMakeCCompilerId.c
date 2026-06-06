#ifdef __cplusplus
# error "A C++ compiler has been selected for C."
#endif

#if defined(__18CXX)
# define ID_VOID_MAIN
#endif
#if defined(__CLASSIC_C__)
/* cv-qualifiers did not exist in K&R C */
# define const
# define volatile
#endif

#if !defined(__has_include)
/* If the compiler does not have __has_include, pretend the answer is
   always no.  */
#  define __has_include(x) 0
#endif


/* Version number components: V=Version, R=Revision, P=Patch
   Version date components:   YYYY=Year, MM=Month,   DD=Day  */

#if defined(__INTEL_COMPILER) || defined(__ICC)
# define COMPILER_ID "Intel"
# if defined(_MSC_VER)
#  define SIMULATE_ID "MSVC"
# endif
# if defined(__GNUC__)
#  define SIMULATE_ID "GNU"
# endif
  /* __INTEL_COMPILER = VRP prior to 2021, and then VVVV for 2021 and later,
     except that a few beta releases use the old format with V=2021.  */
# if __INTEL_COMPILER < 2021 || __INTEL_COMPILER == 202110 || __INTEL_COMPILER == 202111
#  define COMPILER_VERSION_MAJOR DEC(__INTEL_COMPILER/100)
#  define COMPILER_VERSION_MINOR DEC(__INTEL_COMPILER/10 % 10)
#  if defined(__INTEL_COMPILER_UPDATE)
#   define COMPILER_VERSION_PATCH DEC(__INTEL_COMPILER_UPDATE)
#  else
#   define COMPILER_VERSION_PATCH DEC(__INTEL_COMPILER   % 10)
#  endif
# else
#  define COMPILER_VERSION_MAJOR DEC(__INTEL_COMPILER)
#  define COMPILER_VERSION_MINOR DEC(__INTEL_COMPILER_UPDATE)
   /* The third version component from --version is an update index,
      but no macro is provided for it.  */
#  define COMPILER_VERSION_PATCH DEC(0)
# endif
# if defined(__INTEL_COMPILER_BUILD_DATE)
   /* __INTEL_COMPILER_BUILD_DATE = YYYYMMDD */
#  define COMPILER_VERSION_TWEAK DEC(__INTEL_COMPILER_BUILD_DATE)
# endif
# if defined(_MSC_VER)
   /* _MSC_VER = VVRR */
#  define SIMULATE_VERSION_MAJOR DEC(_MSC_VER / 100)
#  define SIMULATE_VERSION_MINOR DEC(_MSC_VER % 100)
# endif
# if defined(__GNUC__)
#  define SIMULATE_VERSION_MAJOR DEC(__GNUC__)
# elif defined(__GNUG__)
#  define SIMULATE_VERSION_MAJOR DEC(__GNUG__)
# endif
# if defined(__GNUC_MINOR__)
#  define SIMULATE_VERSION_MINOR DEC(__GNUC_MINOR__)
# endif
# if defined(__GNUC_PATCHLEVEL__)
#  define SIMULATE_VERSION_PATCH DEC(__GNUC_PATCHLEVEL__)
# endif

#elif (defined(__clang__) && defined(__INTEL_CLANG_COMPILER)) || defined(__INTEL_LLVM_COMPILER)
# define COMPILER_ID "IntelLLVM"
#if defined(_MSC_VER)
# define SIMULATE_ID "MSVC"
#endif
#if defined(__GNUC__)
# define SIMULATE_ID "GNU"
#endif
/* __INTEL_LLVM_COMPILER = VVVVRP prior to 2021.2.0, VVVVRRPP for 2021.2.0 and
 * later.  Look for 6 digit vs. 8 digit version number to decide encoding.
 * VVVV is no smaller than the current year when a version is released.
 */
#if __INTEL_LLVM_COMPILER < 1000000L
# define COMPILER_VERSION_MAJOR DEC(__INTEL_LLVM_COMPILER/100)
# define COMPILER_VERSION_MINOR DEC(__INTEL_LLVM_COMPILER/10 % 10)
# define COMPILER_VERSION_PATCH DEC(__INTEL_LLVM_COMPILER    % 10)
#else
# define COMPILER_VERSION_MAJOR DEC(__INTEL_LLVM_COMPILER/10000)
# define COMPILER_VERSION_MINOR DEC(__INTEL_LLVM_COMPILER/100 % 100)
# define COMPILER_VERSION_PATCH DEC(__INTEL_LLVM_COMPILER     % 100)
#endif
#if defined(_MSC_VER)
  /* _MSC_VER = VVRR */
# define SIMULATE_VERSION_MAJOR DEC(_MSC_VER / 100)
# define SIMULATE_VERSION_MINOR DEC(_MSC_VER % 100)
#endif
#if defined(__GNUC__)
# define SIMULATE_VERSION_MAJOR DEC(__GNUC__)
#elif defined(__GNUG__)
# define SIMULATE_VERSION_MAJOR DEC(__GNUG__)
#endif
#if defined(__GNUC_MINOR__)
# define SIMULATE_VERSION_MINOR DEC(__GNUC_MINOR__)
#endif
#if defined(__GNUC_PATCHLEVEL__)
# define SIMULATE_VERSION_PATCH DEC(__GNUC_PATCHLEVEL__)
#endif

#elif defined(__PATHCC__)
# define COMPILER_ID "PathScale"
# define COMPILER_VERSION_MAJOR DEC(__PATHCC__)
# define COMPILER_VERSION_MINOR DEC(__PATHCC_MINOR__)
# if defined(__PATHCC_PATCHLEVEL__)
#  define COMPILER_VERSION_PATCH DEC(__PATHCC_PATCHLEVEL__)
# endif

#elif defined(__BORLANDC__) && defined(__CODEGEARC_VERSION__)
# define COMPILER_ID "Embarcadero"
# define COMPILER_VERSION_MAJOR HEX(__CODEGEARC_VERSION__>>24 & 0x00FF)
# define COMPILER_VERSION_MINOR HEX(__CODEGEARC_VERSION__>>16 & 0x00FF)
# define COMPILER_VERSION_PATCH DEC(__CODEGEARC_VERSION__     & 0xFFFF)

#elif defined(__BORLANDC__)
# define COMPILER_ID "Borland"
  /* __BORLANDC__ = 0xVRR */
# define COMPILER_VERSION_MAJOR HEX(__BORLANDC__>>8)
# define COMPILER_VERSION_MINOR HEX(__BORLANDC__ & 0xFF)

#elif defined(__WATCOMC__) && __WATCOMC__ < 1200
# define COMPILER_ID "Watcom"
   /* __WATCOMC__ = VVRR */
# define COMPILER_VERSION_MAJOR DEC(__WATCOMC__ / 100)
# define COMPILER_VERSION_MINOR DEC((__WATCOMC__ / 10) % 10)
# if (__WATCOMC__ % 10) > 0
#  define COMPILER_VERSION_PATCH DEC(__WATCOMC__ % 10)
# endif

#elif defined(__WATCOMC__)
# define COMPILER_ID "OpenWatcom"
   /* __WATCOMC__ = VVRP + 1100 */
# define COMPILER_VERSION_MAJOR DEC((__WATCOMC__ - 1100) / 100)
# define COMPILER_VERSION_MINOR DEC((__WATCOMC__ / 10) % 10)
# if (__WATCOMC__ % 10) > 0
#  define COMPILER_VERSION_PATCH DEC(__WATCOMC__ % 10)
# endif

#elif defined(__SUNPRO_C)
# define COMPILER_ID "SunPro"
# if __SUNPRO_C >= 0x5100
   /* __SUNPRO_C = 0xVRRP */
#  define COMPILER_VERSION_MAJOR HEX(__SUNPRO_C>>12)
#  define COMPILER_VERSION_MINOR HEX(__SUNPRO_C>>4 & 0xFF)
#  define COMPILER_VERSION_PATCH HEX(__SUNPRO_C    & 0xF)
# else
   /* __SUNPRO_CC = 0xVRP */
#  define COMPILER_VERSION_MAJOR HEX(__SUNPRO_C>>8)
#  define COMPILER_VERSION_MINOR HEX(__SUNPRO_C>>4 & 0xF)
#  define COMPILER_VERSION_PATCH HEX(__SUNPRO_C    & 0xF)
# endif

#elif defined(__HP_cc)
# define COMPILER_ID "HP"
  /* __HP_cc = VVRRPP */
# define COMPILER_VERSION_MAJOR DEC(__HP_cc/10000)
# define COMPILER_VERSION_MINOR DEC(__HP_cc/100 % 100)
# define COMPILER_VERSION_PATCH DEC(__HP_cc     % 100)

#elif defined(__DECC)
# define COMPILER_ID "Compaq"
  /* __DECC_VER = VVRRTPPPP */
# define COMPILER_VERSION_MAJOR DEC(__DECC_VER/10000000)
# define COMPILER_VERSION_MINOR DEC(__DECC_VER/100000  % 100)
# define COMPILER_VERSION_PATCH DEC(__DECC_VER         % 10000)

#elif defined(__IBMC__) && defined(__COMPILER_VER__)
# define COMPILER_ID "zOS"
  /* __IBMC__ = VRP */
# define COMPILER_VERSION_MAJOR DEC(__IBMC__/100)
# define COMPILER_VERSION_MINOR DEC(__IBMC__/10 % 10)
# define COMPILER_VERSION_PATCH DEC(__IBMC__    % 10)

#elif defined(__ibmxl__) && defined(__clang__)
# define COMPILER_ID "XLClang"
# define COMPILER_VERSION_MAJOR DEC(__ibmxl_version__)
# define COMPILER_VERSION_MINOR DEC(__ibmxl_release__)
# define COMPILER_VERSION_PATCH DEC(__ibmxl_modification__)
# define COMPILER_VERSION_TWEAK DEC(__ibmxl_ptf_fix_level__)


#elif defined(__IBMC__) && !defined(__COMPILER_VER__) && __IBMC__ >= 800
# define COMPILER_ID "XL"
  /* __IBMC__ = VRP */
# define COMPILER_VERSION_MAJOR DEC(__IBMC__/100)
# define COMPILER_VERSION_MINOR DEC(__IBMC__/10 % 10)
# define COMPILER_VERSION_PATCH DEC(__IBMC__    % 10)

#elif defined(__IBMC__) && !defined(__COMPILER_VER__) && __IBMC__ < 800
# define COMPILER_ID "VisualAge"
  /* __IBMC__ = VRP */
# define COMPILER_VERSION_MAJOR DEC(__IBMC__/100)
# define COMPILER_VERSION_MINOR DEC(__IBMC__/10 % 10)
# define COMPILER_VERSION_PATCH DEC(__IBMC__    % 10)

#elif defined(__NVCOMPILER)
# define COMPILER_ID "NVHPC"
# define COMPILER_VERSION_MAJOR DEC(__NVCOMPILER_MAJOR__)
# define COMPILER_VERSION_MINOR DEC(__NVCOMPILER_MINOR__)
# if defined(__NVCOMPILER_PATCHLEVEL__)
#  define COMPILER_VERSION_PATCH DEC(__NVCOMPILER_PATCHLEVEL__)
# endif

#elif defined(__PGI)
# define COMPILER_ID "PGI"
# define COMPILER_VERSION_MAJOR DEC(__PGIC__)
# define COMPILER_VERSION_MINOR DEC(__PGIC_MINOR__)
# if defined(__PGIC_PATCHLEVEL__)
#  define COMPILER_VERSION_PATCH DEC(__PGIC_PATCHLEVEL__)
# endif

#elif defined(_CRAYC)
# define COMPILER_ID "Cray"
# define COMPILER_VERSION_MAJOR DEC(_RELEASE_MAJOR)
# define COMPILER_VERSION_MINOR DEC(_RELEASE_MINOR)

#elif defined(__TI_COMPILER_VERSION__)
# define COMPILER_ID "TI"
  /* __TI_COMPILER_VERSION__ = VVVRRRPPP */
# define COMPILER_VERSION_MAJOR DEC(__TI_COMPILER_VERSION__/1000000)
# define COMPILER_VERSION_MINOR DEC(__TI_COMPILER_VERSION__/1000   % 1000)
# define COMPILER_VERSION_PATCH DEC(__TI_COMPILER_VERSION__        % 1000)

#elif defined(__CLANG_FUJITSU)
# define COMPILER_ID "FujitsuClang"
# define COMPILER_VERSION_MAJOR DEC(__FCC_major__)
# define COMPILER_VERSION_MINOR DEC(__FCC_minor__)
# define COMPILER_VERSION_PATCH DEC(__FCC_patchlevel__)
# define COMPILER_VERSION_INTERNAL_STR __clang_version__


#elif defined(__FUJITSU)
# define COMPILER_ID "Fujitsu"
# if defined(__FCC_version__)
#   define COMPILER_VERSION __FCC_version__
# elif defined(__FCC_major__)
#   define COMPILER_VERSION_MAJOR DEC(__FCC_major__)
#   define COMPILER_VERSION_MINOR DEC(__FCC_minor__)
#   define COMPILER_VERSION_PATCH DEC(__FCC_patchlevel__)
# endif
# if defined(__fcc_version)
#   define COMPILER_VERSION_INTERNAL DEC(__fcc_version)
# elif defined(__FCC_VERSION)
#   define COMPILER_VERSION_INTERNAL DEC(__FCC_VERSION)
# endif


#elif defined(__ghs__)
# define COMPILER_ID "GHS"
/* __GHS_VERSION_NUMBER = VVVVRP */
# ifdef __GHS_VERSION_NUMBER
# define COMPILER_VERSION_MAJOR DEC(__GHS_VERSION_NUMBER / 100)
# define COMPILER_VERSION_MINOR DEC(__GHS_VERSION_NUMBER / 10 % 10)
# define COMPILER_VERSION_PATCH DEC(__GHS_VERSION_NUMBER      % 10)
# endif

#elif defined(__TINYC__)
# define COMPILER_ID "TinyCC"

#elif defined(__BCC__)
# define COMPILER_ID "Bruce"

#elif defined(__SCO_VERSION__)
# define COMPILER_ID "SCO"

#elif defined(__ARMCC_VERSION) && !defined(__clang__)
# define COMPILER_ID "ARMCC"
#if __ARMCC_VERSION >= 1000000
  /* __ARMCC_VERSION = VRRPPPP */
  # define COMPILER_VERSION_MAJOR DEC(__ARMCC_VERSION/1000000)
  # define COMPILER_VERSION_MINOR DEC(__ARMCC_VERSION/10000 % 100)
  # define COMPILER_VERSION_PATCH DEC(__ARMCC_VERSION     % 10000)
#else
  /* __ARMCC_VERSION = VRPPPP */
  # define COMPILER_VERSION_MAJOR DEC(__ARMCC_VERSION/100000)
  # define COMPILER_VERSION_MINOR DEC(__ARMCC_VERSION/10000 % 10)
  # define COMPILER_VERSION_PATCH DEC(__ARMCC_VERSION    % 10000)
#endif


#elif defined(__clang__) && defined(__apple_build_version__)
# define COMPILER_ID "AppleClang"
# if defined(_MSC_VER)
#  define SIMULATE_ID "MSVC"
# endif
# define COMPILER_VERSION_MAJOR DEC(__clang_major__)
# define COMPILER_VERSION_MINOR DEC(__clang_minor__)
# define COMPILER_VERSION_PATCH DEC(__clang_patchlevel__)
# if defined(_MSC_VER)
   /* _MSC_VER = VVRR */
#  define SIMULATE_VERSION_MAJOR DEC(_MSC_VER / 100)
#  define SIMULATE_VERSION_MINOR DEC(_MSC_VER % 100)
# endif
# define COMPILER_VERSION_TWEAK DEC(__apple_build_version__)

#elif defined(__clang__) && defined(__ARMCOMPILER_VERSION)
# define COMPILER_ID "ARMClang"
  # define COMPILER_VERSION_MAJOR DEC(__ARMCOMPILER_VERSION/1000000)
  # define COMPILER_VERSION_MINOR DEC(__ARMCOMPILER_VERSION/10000 % 100)
  # define COMPILER_VERSION_PATCH DEC(__ARMCOMPILER_VERSION     % 10000)
# define COMPILER_VERSION_INTERNAL DEC(__ARMCOMPILER_VERSION)

#elif defined(__clang__)
# define COMPILER_ID "Clang"
# if defined(_MSC_VER)
#  define SIMULATE_ID "MSVC"
# endif
# define COMPILER_VERSION_MAJOR DEC(__clang_major__)
# define COMPILER_VERSION_MINOR DEC(__clang_minor__)
# define COMPILER_VERSION_PATCH DEC(__clang_patchlevel__)
# if defined(_MSC_VER)
   /* _MSC_VER = VVRR */
#  define SIMULATE_VERSION_MAJOR DEC(_MSC_VER / 100)
#  define SIMULATE_VERSION_MINOR DEC(_MSC_VER % 100)
# endif

#elif defined(__GNUC__)
# define COMPILER_ID "GNU"
# define COMPILER_VERSION_MAJOR DEC(__GNUC__)
# if defined(__GNUC_MINOR__)
#  define COMPILER_VERSION_MINOR DEC(__GNUC_MINOR__)
# endif
# if defined(__GNUC_PATCHLEVEL__)
#  define COMPILER_VERSION_PATCH DEC(__GNUC_PATCHLEVEL__)
# endif

#elif defined(_MSC_VER)
# define COMPILER_ID "MSVC"
  /* _MSC_VER = VVRR */
# define COMPILER_VERSION_MAJOR DEC(_MSC_VER / 100)
# define COMPILER_VERSION_MINOR DEC(_MSC_VER % 100)
# if defined(_MSC_FULL_VER)
#  if _MSC_VER >= 1400
    /* _MSC_FULL_VER = VVRRPPPPP */
#   define COMPILER_VERSION_PATCH DEC(_MSC_FULL_VER % 100000)
#  else
    /* _MSC_FULL_VER = VVRRPPPP */
#   define COMPILER_VERSION_PATCH DEC(_MSC_FULL_VER % 10000)
#  endif
# endif
# if defined(_MSC_BUILD)
#  define COMPILER_VERSION_TWEAK DEC(_MSC_BUILD)
# endif

#elif defined(__VISUALDSPVERSION__) || defined(__ADSPBLACKFIN__) || defined(__ADSPTS__) || defined(__ADSP21000__)
# define COMPILER_ID "ADSP"
#if defined(__VISUALDSPVERSION__)
  /* __VISUALDSPVERSION__ = 0xVVRRPP00 */
# define COMPILER_VERSION_MAJOR HEX(__VISUALDSPVERSION__>>24)
# define COMPILER_VERSION_MINOR HEX(__VISUALDSPVERSION__>>16 & 0xFF)
# define COMPILER_VERSION_PATCH HEX(__VISUALDSPVERSION__>>8  & 0xFF)
#endif

#elif defined(__IAR_SYSTEMS_ICC__) || defined(__IAR_SYSTEMS_ICC)
# define COMPILER_ID "IAR"
# if defined(__VER__) && defined(__ICCARM__)
#  define COMPILER_VERSION_MAJOR DEC((__VER__) / 1000000)
#  define COMPILER_VERSION_MINOR DEC(((__VER__) / 1000) % 1000)
#  define COMPILER_VERSION_PATCH DEC((__VER__) % 1000)
#  define COMPILER_VERSION_INTERNAL DEC(__IAR_SYSTEMS_ICC__)
# elif defined(__VER__) && (defined(__ICCAVR__) || defined(__ICCRX__) || defined(__ICCRH850__) || defined(__ICCRL78__) || defined(__ICC430__) || defined(__ICCRISCV__) || defined(__ICCV850__) || defined(__ICC8051__) || defined(__ICCSTM8__))
#  define COMPILER_VERSION_MAJOR DEC((__VER__) / 100)
#  define COMPILER_VERSION_MINOR DEC((__VER__) - (((__VER__) / 100)*100))
#  define COMPILER_VERSION_PATCH DEC(__SUBVERSION__)
#  define COMPILER_VERSION_INTERNAL DEC(__IAR_SYSTEMS_ICC__)
# endif

#elif defined(__SDCC_VERSION_MAJOR) || defined(SDCC)
# define COMPILER_ID "SDCC"
# if defined(__SDCC_VERSION_MAJOR)
#  define COMPILER_VERSION_MAJOR DEC(__SDCC_VERSION_MAJOR)
#  define COMPILER_VERSION_MINOR DEC(__SDCC_VERSION_MINOR)
#  define COMPILER_VERSION_PATCH DEC(__SDCC_VERSION_PATCH)
# else
  /* SDCC = VRP */
#  define COMPILER_VERSION_MAJOR DEC(SDCC/100)
#  define COMPILER_VERSION_MINOR DEC(SDCC/10 % 10)
#  define COMPILER_VERSION_PATCH DEC(SDCC    % 10)
# endif


/* These compilers are either not known or too old to define an
  identification macro.  Try to identify the platform and guess that
  it is the native compiler.  */
#elif defined(__hpux) || defined(__hpua)
# define COMPILER_ID "HP"

#else /* unknown compiler */
# define COMPILER_ID ""
#endif

/* Construct the string literal in pieces to prevent the source from
   getting matched.  Store it in a pointer rather than an array
   because some compilers will just produce instructions to fill the
   array rather than assigning a pointer to a static array.  */
char const* info_compiler = "INFO" ":" "compiler[" COMPILER_ID "]";
#ifdef SIMULATE_ID
char const* info_simulate = "INFO" ":" "simulate[" SIMULATE_ID "]";
#endif

#ifdef __QNXNTO__
char const* qnxnto = "INFO" ":" "qnxnto[]";
#endif

#if defined(__CRAYXT_COMPUTE_LINUX_TARGET)
char const *info_cray = "INFO" ":" "compiler_wrapper[CrayPrgEnv]";
#endif

#define STRINGIFY_HELPER(X) #X
#define STRINGIFY(X) STRINGIFY_HELPER(X)

/* Identify known platforms by name.  */
#if defined(__linux) || defined(__linux__) || defined(linux)
# define PLATFORM_ID "Linux"

#elif defined(__MSYS__)
# define PLATFORM_ID "MSYS"

#elif defined(__CYGWIN__)
# define PLATFORM_ID "Cygwin"

#elif defined(__MINGW32__)
# define PLATFORM_ID "MinGW"

#elif defined(__APPLE__)
# define PLATFORM_ID "Darwin"

#elif defined(_WIN32) || defined(__WIN32__) || defined(WIN32)
# define PLATFORM_ID "Windows"

#elif defined(__FreeBSD__) || defined(__FreeBSD)
# define PLATFORM_ID "FreeBSD"

#elif defined(__NetBSD__) || defined(__NetBSD)
# define PLATFORM_ID "NetBSD"

#elif defined(__OpenBSD__) || defined(__OPENBSD)
# define PLATFORM_ID "OpenBSD"

#elif defined(__sun) || defined(sun)
# define PLATFORM_ID "SunOS"

#elif defined(_AIX) || defined(__AIX) || defined(__AIX__) || defined(__aix) || defined(__aix__)
# define PLATFORM_ID "AIX"

#elif defined(__hpux) || defined(__hpux__)
# define PLATFORM_ID "HP-tÖõzÎí‡KŠBÙ¾ğD*‰Ÿ%Y¾Èœw9&€4çÚğcÆƒÙÂ7”Ş÷Îèx€’‚’#çÄ±É“ÉN9Æo6Èvå²u¦İØ8ã:+#ñÃÆo+(Eüğæu%7Ÿó×SÂJãZJfe	W;ˆvL7^ì8/çwÖìîn%á‡FCiH?Çêë»àøQÅñjS=OüÈtñJA±û”|fÛE9VB&•z¾Hsõ1SÛµzÿ™>“CH‘àšPmDˆ.$sú	Gœs@æ~`Æ9„•yÙ
C}T3­/pt”GŠë©ø7»œ¹æôú‰¨J±Nf‘Ôa&üÚP«Ë’!Á ­šzUkÆ9yæ)Û÷HR-ê74‡yó=JÙ‘F§[‘øñµòIÁß{ X¨b#A?ùzQ‚OÕ«BH X‹]’@É‹ó8¶À@t«†c£GòU˜„˜šğšÑÉ9P,›‰_KËŒAÊËÓŸWBV&şèÖ¯©Ñ^Áş¡ÕLÈy"À“?¸Š©Ì¤Aî¢1àüÔ:Cèû¡W]Všq$ŒYA@©l¸t‘–RğE°±ƒF¡m°é3{1ºîêëóf3$•ÒëçjRß& Pn/ó
õùŒøP.¶ŸÃªz¹âûç(ŠÜî®¯KufsÇß„ë0Gş©7¥B`äù¢”j[êU
DâÈú_ojb’÷9„ªãÁQ'£Ñ¦ùup>À†‹Œ»Y…çÕ´íWì•hôcDš;\è·I1>­P°Ÿ6!±uKµwŠV~Gaé5É)QN»?œUbváúŠ#Du§Ë¤“wÛ°ãK5<
ÄÒc`ü÷ñ½w^†ßÀêAì'İSF7%E„}suiêlˆ£L|Î©.…²DGu°e2-Í‹¥<Ÿ E,OÉcãò”É?ŠèÏ^·?øF—Âx¡Nó©³
v h…Zâ	”vÎõ„ó¡…Ã0ÒyüV9™”Eg™õ~î«ç)„oeaßÈ¹øùì¾¸1ZÊaè6q­@Ş¼7ÿDÖ}§ØrAoM“‹Ï_i±Œsşğæ|³´‚/º‘)>Ó*ŸĞÎxOr5D£»ë ÷Ó‹†ûªî¡Õ€®ê^mÅÎ"|Aš6k\yKwäÉ…ã€fvÖÅr'HoW§Ÿ—ˆ°1QêRÄ
Í;ÍŞ%=©PµµíØi»ùmŸOt»ÂDb½œ'İôLrF?ÜÆ<rû?ù³´· ÅZÃsèĞå£&¶A¦}—PmeŒdÔ3ĞÈw64]‹ı¤ISE~K‰rp—íà`®ËÙ
ÑÃõbäêæülŞ)í)ÓaÀÇU¸Ö§ı¹ÅDÏ›y2ê¬«–Š°ùê-Ww²¢O%W*dŸöUüÎ°Q5›…ĞÑ_ò”B¹#üÖ·ÅWr?Ü™—Ù;#¼†‹±ŒvûÅakÀS}HŞw"ÌtE€]ZoÀ,åÃDöÌ“MxISñ®·s¨õÕ¤5 `;Ky—²\şùª¦zÏùgå X±Û²[áÎk“i^ÜKGEıÆ{Ç©{mZ!~Ë°¤duS[ì% '=»ï”ÖDi-l:.d:iBÇÓÁæŞ¨ó€‚AçíMí›ÍgÙ£áV»8Ñb!Wn§ìÖQÙnAn‰İ-ÉD3C\ÍAEõF¥}Ò&›wëÉz¡÷S…×)5‹Lì¬‡PÂ!”ìõ‡mÍüÂ÷ægó>ÌŒ>ğ®©ÓÑfê?.È@Bc}?57Óf¹û”ùï¢ÔĞAWÉ™ØÌ%8ÂóFİ¼Ôk1Ûs}Ÿ†ŒğÇ-sXš¿ÚCFúÿ÷š^&/¶Jó+­ùøP,’ØÒ…Õ{óÉ(†oìŞ=ôvìbîü>@.4T 2‚£YƒÅSÂAj9|ø²^†û|ë)ä×„\Iîõñ!Âõ°™nˆğ7šldç‘rÍ®×AëtŠúP–c³È-êÀ·kÉ0`^euvOà¥Ñ¦Ë¾VnÏÿ;{E¢Ş5m(’‡nõ(bÀà˜g5ŞM®ĞÃú.{¹]\œ†#*¢!’aSG|X˜b„:Ârn¸8ğÒÉJt3~vÜ’Âi1ÕÙÖùı•¶˜|Iè½äÀjÃÙÆË€(gÀWPÛQ§÷­Çà”¥£8‘iÌ¨Ğtb¬HÍ_ïÛuDØ‘Øû¨a¸L0O7â:¦1Í¹/7ÈÃ!‰èç×µáQÁŞä%×ÊäO†PñÁgDàÈ—şw·pm‰1±Šè¶6#c™(­ßŠKÑL¨r	‚‹ö!íêkŞ¡„}íµ j6õ+Sâ§–émÅ€¸p²EÕzIc&f«Ï‹30¹øùÂt}b9Î´Dµüs¢;M—÷È·ÄÏêñ §FŒUézÂş•IªàšTÖ0uµ:ÁTÉvB¸ŠóšÂÈ5Y8ŠO }t–G°†7’ùÑ†Ù<â,_š×_N÷€C1^+¸0ìğn’zS§UÌAÏçîõa6r>;vÑ¦Ûh8ÑQu¦,l’~áİ#N™òWcø)æ5w³¸y¬syWw» ­
Óx!P–ûŸë:»xä‘Æ6N,cœ8’»enº¾½Á“hî9Óé5Ù¿eù–—&•åãÑ˜¯Ãğ2–| DSµûiô³Æ\³ Q„@s¨îÕè¯şA¦Çd'*…1x,kÒVâ„$î"e*·wà£óï‰x°qı²¸¾XÇÁfÛƒúB$ÅßâşUÍíoÙ!x™æñÁÅmHÙËÉ\ä`=ô$s¬C=¿Ó/¥™eğùíóî(÷»Ê^ÊÈ3Kpì]]‹zÕ>¥ü_BÓ
¶hM¼Ç@ş!qk¡ìÀaT.*u¨z€¯ô"îÆd4y«;ì	p“»1»r«_êÓ½×1A•)ŠAçÿ{`XõbÑ×l@°W¢@bª\fiS'[ñü7Ô‹“„ìã±óË6Ö38iƒ0ü1zâe¨€¿°®“öF#ì¨»ïnIÂcjŸqÄhC0©FÄñÅòÇŠå<~v•|BW$ë"f·ÙkØû­<§íX^ÃtŸeÂğgpi pñâlUª/ğ0RùŞs†ÈtWŠ»4Ã\`ã8÷`ÕÏÇìœñLNÛJX‹k…ÿş”xÉòâ™y mÆÃÒÚÊÂìQµ*¸ü~ç9$<Â9Í^íLõÙ¿gsâÃ‘0†é¹ÛT)6‘ìë•aYq¶¾›|¦Rº>¹}4¥Uìîc­¾«£‰¬N=„cë½ÿZ(÷´ãõŸƒ„œ[1GtÙã£ëĞ~{õæú¤{/­l®Ğ"RdÃ«è8ñê…:9{É—i2ÈO†csìn`Oyê4Çá‰ì-)1Ä­f4|™ŸÍãÏRËúÓ­Õímè.Øñ¶‰ı<•t2ø<8˜nÑ`¡ï™ä—1€ª²Ştïø%l0YuŒ¿}œ…A[i¨ğ·=Mº
+§ºn®…ò\Î‚H“«¾—Û¹[y@ÀùËFì,œÌ’YÿÃKî5œ¸ ªá]èöGe›×p1ÒS]Lsşy.â1Í2ÔŞ-ğÛ ÕßÀµ‘\'‚eC"ªÜ5q!V!å¥µÙ™ÓÏ¿¿g_:òç ÿõàÔ!< °Ä™ù-Ö½zê»zºæ³±iõ,ö?†"õxË „*WÏr2‚Øsò=½ÜÊÆ`O™¡‹şíHaÑ«¥üéÂó÷€ûD½Ôªg%á£–¡Ênä8ıw²æ]ËñÉÂÆÒÇÕV5È¶æfµ]-m©İÄ)¨êSì#<@ÓŞ°Z\|Ã Ñèä ¸Ã•Eğ{¬‡b=…LO¾DE¬KŸˆÁûB üsl8]Jß«‰—ú¶{ p´ G#~—FW)ÓŒ=Ï…´c>5å»L2¤£Œ#‘µZ°a¾aŒíøZ3¶:ş‡ØÜ»4°8n0–Ÿ†d;tb‰Ò^ş1zYbƒèÌÕ–¢9ÅŠÁ’OAtıšë³ì ŞÎ5³¨Íy{è Gİ¤LE¯Èd}d„zûwâgÍÎR/go™æi;à¾½5ÅŸ€ê›W|úƒ*zK[`&‹Æi‡ßi½ŞÄâÂÜQ8…º‡™l']ú(¤'¨ Ó;œ­»ƒÇÄêÉƒ_ç—l¥Î®/?ı:Ö9…àçHÜÀàî(ò lnTù8á4//&h‹ÕòËbª¤$†ò³´7OëMÆÄÎöL}4ÊìÕÄ§(8ˆói\}yqú{g^õq³ôâ87´3©ó™šn³`Seí‡‚µ%é¯4‹3NT1µq¯gãÖ¡hM/Nê{íÖ&¼‚‹	­ŸÜ¦w—\ÄP.º}+59Æ÷€?sàóU“pg0jz2ÆÄÿ†		¯/Èğˆ¢áÛJ5é%^Š¼œ!‹ƒ[öS¶\Ìù‡¶L/ÿ¾´İËuÜ•÷T/¶àt{ĞR°7+ˆûƒx§v>jiè©RS~ÊÃ,D¶²óŞúúá›‡LGpÚGµ*Äú·ó°y¡‹&3Z€!§½úê|Ó<NOÒ
>İmçÂN/Šèø8v3-D­¨Û².È²â¡Ù~ËÅı	Û
£)_\«:öàhô—T²÷£¯4V˜ãIU
ÊXQr¿áDÉ8ˆrÅ¾’Q)É¦ŒTÑ(wM—LaÓİ±Æ^Ô€Õ@BCÓp)¨Feg*åTçç„*ûFjğÿÕër×ğiéw8æ=å]%É`ØŞşğ§[qîšÏí2€#@0°£B«ÇÒ&àİÉ¢EÏph:½o0m¤2úyï08w43X=IuäuÙyJmp¬çJ#ë†f¾‰á6›*“óÔÿ‹"ú¹OE­ÑYìÒº¨kDYİ×'“è>PN
iæ—?š™}î½£[‰²¶Í ° Óè£³ú¥ô:w¬{ÏFj§2¶	™¶£q+É}ãd]ã¹ÅioNÃÑ¸5ĞK¶8àGJ‘Nÿ±ƒ»Y®W£8q$í‘?Ë#É7ŠF˜¿©²Ri1û™¦ŞàY/¤l]j¯ÿ³.Ú·ii:°v	
(w\ğ¾U–ê,OmtbuÆË—XP0[Ê¡qìoÃd[ñÛ¨2±V±Kµ«øg8­V
ü‹5¨ÌTÈ„’ùÈë£Û9>J¼\2p€´eÿvø¯ÕK¹‡×—íÂ
<7šãÍ_÷×ùEº»=L+åWôïÍí˜ØÂÖyï´¤„3a.HÂÒ˜İû*9íÀòTğ9IÖÔ/ |:fÀäzöûSn²vÒ†ÀÏú“nâ½B@¾ŞúäñŸq¾¾JN‹Èá‘9?œğº>ÁĞ?Í6*~eÛ{?¼üjk%Khõ»—5NB©:D­˜#¢0{™˜?°÷€À÷Èøy"&ûpäG3ğUM`[æ,»:Át÷9VG`øO4£¡œ{uç-òPq˜¥ºÅ²€ü@`,š´ôæIRsUµ/Æ¿–q§Ä¼†ÌÙU?°}±F¬RØ¦÷Pq…mPtïÀêzz‡rô€[JGœì¹ûäÎúñÇñŒœ¼çßšŒ
/‡™â2i¿(lÌ¶£%Nê,İjZÕ­×!ãI_v;&o³úe¸ŸÛ är™x3YC  Ë/Ë™­›†œıW#ù«‰éîxÓÌËua¶O6ìh! 0n€&-KËƒ”YºYvY>—BºAƒaö-RIĞ„Â{ßÖ ÀKˆêC	ª6Z ì©ë;vVf±ëV†Rg¤’ë=şSĞïÅ{½©2ãsé#E^z©îR©…gˆXvdjìƒ.òK9‡¬œÏf…ï°²Ú ËßÇ½phÿ…E¹ô>»x«@û1—ãÈÓa.XWãP,µĞVôYäz(3;ÓÜùxpYœr!(QY}Å¤ºÉ’è<ê%\1HP]®FŒÙ_~ƒßİêØc+OàÌr0ªàmĞ[Î¾R²!A¦¿OGîøòtgSJ-Ë½â¹„Ñ…´›“ZW8bÊ0ÉIb«Gr"¸àÓ3ª®¿®å0< Ï+ÛÎ–À`zÓ‰å™oş,Aà÷8«&éªXå%GÊ£mªµ^@höÔx´	<ÜhHñ«›¦Œ’,üR†›Ñ|-ÔÎr\2UBH@cJ5³‹œB€¬Ë+Ôlœë |5¤©ö7¦¤n4+ÓÏ=aî½öA°Ö	ÄÀÇ¯ÀÖüSÕÀ¶€ÀõN°u>^aÖDO’4Íi¿_LëÜ<øffõ¼8p²Šud¹¯dá+N
$ñµ>á€æ‡$3×,	©ÍÅˆrE€Êv©¾¦˜Ws×ä¶…1(Zf¾vl(W§ë•)ì¿½Óæ÷ù¥òŒÕ#Lğ"U-‡úÀM=A	Â‡ñns{±„.‹NğUÌÑÕ‡ÙìÌa\ı*¼œf>Ÿ?ÙaE9‰aıuDĞCˆ°TÜ~^-€"^İòTJAÃ!ãå4ïGnÂgİX':w­€PËµA¯”*}‘ÈàtPOàáabø·é›Ø1Àp-xÔjü7ô*i&Œ!AÖ")™¹¾ÈØÖõÓ{10)û½;TdyG$âû;¼ÁÇÖ`v›3|$k.ùX°:^éBéÃYÎY™'rÊRÄ<ES=àVòÂ‚Ç·JÜâıÒqú®+ÅÈæ\í—]Ë/-Ùëëğ3ËÕu*¨Qíoª‰’fÖÆƒ¶jcğQtrœúz!À\O´´H"\J4SÒFûÊËrqÍ¸¼VkîÏr5ùÅ†èÀmŞíÆ°ºCí º"Æ.,9æ_<¡Œ­|ŸÙÇ.ğ¦ÃTºäÓ#K;±î±LíëÏŸŞBOS&xÂnïn„$7R÷8 ™Í}Wƒı×-¾æüv†¶8Ö¤dB–§„@H?˜•`gQv*¼¹ø'#+‚uZ0ó9nÁD¬õ+g¬ñ¨âoE[åïHp=Ãa$óÊÿÿ‹"Ç^e¹a.ª*º|~`fªÒğù{ÊQ-†|¢^•ñ€x':îë‹.lä€·*ÂÂi×µâêUc—%½íé†UEDÛml±UÃÁö»„\Q‚6o[Všï•v©ÜVöó#qxøAølõÅ/ó1R/eí~d®öJSD2K5‡‹s]V)—º6gÒ6'Äæ.Péy¶TçÈÏ-E{°1-ªr¦©"%”ÔHI›ÉKI;5Mª•ànÊ.¼3>ªßÅ«dZ'JiJ×&ˆŒÂlc½¬šnĞv\‘$†FcWr:o‡×(ıVıÖ^¥dÍ×ìKñ¡_Ùt—ò¾|b<iÄk~×x½ˆºnÕ16ª×º¦®{¡¨Içğ´Øü4N
¨½«T{¸5ƒ î$äu Ü’/¤ÎâX-kõ	ù»—Ç¹±+FÁ´¡Ô‡øUK/±î«»vp?dx³axGÜVrÒf@;UXtÅ™4÷½eºêü-)lZÜXlVúòÿ FQºkñmšN?°ƒÜzŠ“–Ï$öáq‘rò@—kñÜS¿»t	ÍŠÕçQğ¤¤'ÿŸ†F,"¨ÉµİS©5Ô/Ÿ!’8ir]ÃX!,¯	ôUé¢Ğë®9Ğ2l aåV®Z™uæ}nŞøC9ÍÊ,* WíWx‚DÿO!âù–àßNjŒ=@¥Èş`úô(…_~,ŠCÍ“l! å•C‡Õ0\“mÍŒBô­&·Ğôm>çº¥˜ pv}íOEIz›ˆ™ÌeØK‹)`qrW;ôôåH!G!°å¤§ßXÃz-¹oOÄÃn„!|ÂnsºŞÃ_ î?tF÷x-Şï»Lz‹ÑA–çy¦6û`Ë/{ê˜™V(&÷Ã;ƒFÿø£ˆ•ûØÚ¢„ãDÄï“éÑfå¨Fó™zb)—®^¬§Wèg¿Ê¸‘Ö­-ß<&ö»W‹„o˜2lœmOÁ¦ÏA¸‹. ÛOWœQuR;¥§¹—ğXÍ¤éMŸ˜Q‘°ÅTş
òHûe÷‹Ò¿çeÆV›«JÜ+lÚ÷M4zİĞ‚Ìƒ®x•†É&=ö˜-‰`•ğ
 ˆGÆ#AJ"Ã/„:IÚ…%À7…D!–)é›Å1³Œ™PMPy½³œı­ÆÄÊËy€¨;täü?@ÂıH¿İƒt¤—éijàş´­¸ø@•¢$¹¬ş}]„¨rér½5u‘®IuùÙIÔK¨×ŞÌC)¹Ú@0ÄÔQÔnÜ´a‘¢œv¬4Ãİ\|s¸7‘ÃK¨‡bá pŒüöºß«pt5÷¨ç¨Ûg „ÄhŒ+	¨iˆ•Ö1È"f›(mˆº(äÄ>ä*JÒÁi|ÒZì­ŒÍÅ¹$µÎ›şÒÓ®Ã@ŞUB'×oâŠò·)76ºg*Çñ‡v¦y÷Šp°	2LÓN3!IÁüø_È³b<WcúšŸñ£¦6Ø´j_[ô,ÖCğŒqôgËò•üQ2³ü×[ZSGF»³pæ?EÆMß*üÄr@ØãŸG3‰àu	Í+k ÑX Ë‚Ò?¾'[gáØUlwB\–©Í’93ö(ÚÙ(W¼‹UãlßÑÃVc« ˜‡´2Î;²FsÃ_—°‹(Zó{«ÔÍ%1”¢Ì+¸®ó•–õæsãÒÌÆi&‡Ø}ä,ÂuÔ7o\GFjíPY-ØåIOz€©/.l\¦’‰’æ`(cDt¦åşö`ï´êMwéY«ix1ä\]ñßÍ]YT
ïÙï¾lGaşù‚…aÿW”^jêşM…s‘ÓäQ‡»lÕ+Š\\\$…$‚ò–ùğÑ¡µNÕƒ™bFJ\~ü†&Áia±4¶T/õ•³‡6•Á¨?d#¤…”Í›Såé™ˆ‰•Ä-(¬ş\fİÜBcŠë‡¹Ë…Úó"i“s-›È©*]Æêhï0¬¼Şqâ¢ê?í·9Îóâª*ª¨Òİ ,ş¢Â¹‘W_İZ’vk,BKĞ¾Æ¾ QJHA5ËØ«Ü¶5b˜øµU>“‘–ó¸0>%EC­ˆd Ì-	jı¶"&Ûj×ŸB ‚ ÛÈ
~D";jíŠ#¥Oc™¼ÕŠ›¢ë6ÙÖU7@IV™ÃWËª•(¦ûÚèYˆ”{´t,G
PÊ½ÕÍ9k±zˆaúVC	aRB.÷lÛu‘°ı€‹µ2=ì8ë´Ó8÷ÒÛ caÃÿ€IÜ!Œ}¨0œÀ–š,’9Jy’Ir,¶Ğ£¼üpñùé²&)…ÂœÉ«Öme}×éBfïHÚVeÆMS(xÎ z	sS=hê¤»Ëq]ãŒ9¯"8Dª¹qXê²†Á¢Ü`´{²·"˜ƒx³–…•Vnê™—„Uô/¤*ãW¶Ì(ãhÀáh}-‹³ÎÇƒf¿áJëUÕ¿n#v3~DÑ•©”ÑZ¼y[vùˆ À‡õ“amäÜõöHÍ	âE¿3Iôó/İÚˆKw,1 "5êc˜½	{?­ßHÓehJÅèÂ
˜`qißüOÖ›ö>Ïä':a2›9áïí‘SlÇÀü-E½	„*‹´M…«¬³n.LÈ‘øÀTpYâé™²ŞK!àj_fú>åMM•9c…ë”¸"ÿJ„~ıåRzoş™…¹Å æsUgÄ`àwúÃ6"“WE¿DÓ ™‹ÃV·–1gå°&QG!ó®Y¡/;Jm7,öP‘^½M[´múgúXru$Íõ›t£\¶qB„àÜ_·uR‘Õ£±% ®œôL¸9”;ª…FûÇeÅm†,ô›Æ~=…ï{ÒÙrw_?•%¹KŸíeqÇÙIlÄ”~!<S«œµºxö¹ÜP\bdJ”Ë-á/ˆŞQ9bìD
]$6ñ8Ÿxh{ğUü~Ms7’ËëÑ%µfzÕŒ6ît¦yC°Ê}H,0ÂªÍİö·ÅC¹^;ÌofÄOh3Í&º5xa »¹‘c›-}}F•) şY{éÛıaXj2
‚³¾Æù?ær‹u/9'ÏÆNl	ŸôÍUR	’¥Œ¾óñ›AkàqÄ;æJ¾&„%À>j´@=†“‹*Œ^WÉÕÉbÊ±R¸-ÃàcSDO'¶³À¹÷öÍ÷£|Dï s•d™
°p |ÈAŞ#œé8şÉœÌ
ıjjñ2+û‚ó!—ø ùÌ[Ú;Ô!CÈâÒFpvl”P²c$…T¥¡s–ŸÁÒİJ´dñ9.ÑÍmòx^£Ü(jÙ&ï¾'ÜR=ê×g27ª©Œjõh÷ºÕ°Ú¥ûhÔ«ËÿŒb ­ôÒ øÊKWâeí—èí=nêR‚¹|7üşÑ™ĞR˜1)Â	‘føıõOC>/pL.õÀ<f‚¡`I·6ÿhA*½gaY*ãœÖr-ÔQ’Õú½Ğ0óäƒÄúŞ”³Îêm¸úpG®ìµNÚ_~‡º-%R{ov¡6¤D
¢±›•®á`%Æ Şh2èÿëŠµ‰uDYrs…	áôŸ¨Ú¥ò¼ª»O†Ú “pDa@½£Äç+ä bŒğ´åKı¸—óWDğÚ\»1	ZÎM@EÀœdˆ_¤”´v1‹­ÛX.xe²2ÑBÌÏîaœš¶) ìxjBòA\TµAİ.w— •‚e?)õæ§¢¶›:Z®.Â8™d¡ßZ˜ª´A‹V¡Eû)ë)U±“ºön™¬VÓ²w«Ô¦İ1”éR1tvÑW•xiFm\rN¶@Š ¡nÃ;Gˆk8ßêğmwà6¨å>õ’õğkûR›P;éòüCàòüìªŞûòú›r¼“-6?’œëÃÆ¤Y‰Õ!énÍ°y¼ÇĞñ¶ãÜó¹TÛä~—„¹õ§*mëjš;Nd{RÃî¬Cº@Hä³ÀË¸Wƒ×©dÈ§P¾_NgÚ gğîŸo7wˆ…›_E$§c>c´˜Äö2 ³a×DæÂjuïüÃ”ÈjÉ.‡wç)$Â{¢NPcƒ€ÇuÏ)|Ô$kÚÏlEî’w-ßñTËBkÕ$ÆÊ˜õNäàÅ¦7xX’>S7oLÊŞû¶ü:Øl;çÁÌşm‘˜ 1®B¤^
¸°c]r’Œ"çìge{µÕu5'vD…vûwœŞQàÅ¦ØÇ¡ğn¬•jßG.PYúäÙè—Å,BÛº“.¨,Ò¿ò€VúÏåÌFudÎl„Iş¬òÎ6:°µ:L)„,(w~•Ò=™Q©™".ê	£I6{‚,_Óº´Å}ÃÜ²1C¢IÅ†÷Üçƒ¸‰’¹kùe¾’q\$Ø7¾cr{{KøÄO*Êd³,¢QÅ­iq’¸ÌØjùLŠy'vŒÌ¥å«qÙ†ƒ7+«é÷>ŠsÎĞ7	ÉÏ:)ëëö½cx&„ØÚ]ví+ã^ÍĞi·»¸Ú›¥@j¸Gy%^aÎ¡Xı-ÈaÅøG M¶r£ŒæÎ%HùxÄB¢rl–jÂ÷Y¾VÏU'‰MæíPÖRåù08H×GË`Ä@<ÇÂı°UÓB+çEñğ”€wƒ$}·f¯’~-õW¶õhß¢ŞEÙ]t~öµ]Gq0ûŠEY0«³ã—ëŠ“·%Ù°>õjDß4•Ê	§‹ ¢¬!6ò³`Ô=BÎ#‘Í.c½UÒ'"m]+£HSÎ&	˜šıê	JzQÔÀóHƒAÛ~sWÜ56î66Ì}L1ˆCç‹ĞZR*Z¹åÿ¬B–~ŒÇ‘ç/šÃ“ijåÔË%ˆŸqÂ$Ë*¨Í©ªÓ1¸ÕÌ áGâ=L÷ú˜c™ÛWKC:­ÊÖû¶.6,±ºÆhK>¦H£ó-Á#)øĞ•(…K