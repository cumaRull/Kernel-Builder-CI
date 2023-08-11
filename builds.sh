#!/bin/bash

TANGGAL=$(date +"%F-%S")
START=$(date +"%s")
KERNEL_DIR=$(pwd)
NAME_KERNEL_FILE="$1"
chat_id="$TG_CHAT"
token="6118183207:AAEr_wwQkj1qGLTfeBYcLP9C1bBlgJ3xDwc"

#INFROMATION NAME KERNEL
export KBUILD_BUILD_USER=$(grep kbuild_user $NAME_KERNEL_FILE | cut -f2 -d"=" )
export KBUILD_BUILD_HOST=$(grep kbuild_host $NAME_KERNEL_FILE | cut -f2 -d"=" )
export LOCALVERSION=$(grep local_version $NAME_KERNEL_FILE | cut -f2 -d"=" )
NAME_KERNEL=$(grep name_zip $NAME_KERNEL_FILE | cut -f2 -d"=" )
VENDOR_NAME=$(grep vendor_name $NAME_KERNEL_FILE | cut -f2 -d"=" )
DEVICE_NAME=$(grep device_name $NAME_KERNEL_FILE | cut -f2 -d"=" )
DEFCONFIG_NAME=$(grep defconfig_name $NAME_KERNEL_FILE | cut -f2 -d"=" )
DEFCONFIG_FLAG=$(grep defconfig_flag $NAME_KERNEL_FILE | cut -f2 -d"=" )

#INFORMATION GATHER LINK
LINK_KERNEL=$(grep link_kernel $NAME_KERNEL_FILE | cut -f2 -d"=" )
#LINK_GCC_AARCH64=$(grep link_gcc_aarch64 $NAME_KERNEL_FILE | cut -f2 -d"=" )
#LINK_GCC_ARM=$(grep link_gcc_arm $NAME_KERNEL_FILE | cut -f2 -d"=" )
#LINK_CLANG=$(grep link_clang $NAME_KERNEL_FILE | cut -f2 -d"=" )
LINK_anykernel=$(grep link_anykernel $NAME_KERNEL_FILE | cut -f2 -d"=" )
# toolchains bro
LINK_TOOLCHAINS=$(grep link_toolchains $NAME_KERNEL_FILE | cut -f2 -d"=" )

initial_kernel() {
   git clone --depth=1 --recurse-submodules -j8 --single-branch $LINK_KERNEL ~/kernel
   cd ~/kernel
}

clone_git() {
  cd ~/kernel
  # download toolchains
  git clone --depth=1 $LINK_anykernel ~/AnyKernel
  
  #proton clang
  #git clone --depth=1 https://github.com/kdrag0n/proton-clang.git clang
  
  #clang 14
 # git clone --depth=1 $LINK_CLANG clang
 # clang for exynos 850
 
  # BY ZYCROMERZ
  # git clone --depth=1 https://github.com/ZyCromerZ/aarch64-zyc-linux-gnu -b 13 aarch64-gcc
  # git clone --depth=1 https://github.com/ZyCromerZ/arm-zyc-linux-gnueabi -b 13 aarch32-gcc

  # BY ETERNAL COMPILER
 # git clone --depth=1 $LINK_GCC_AARCH64 aarch64-gcc
 # git clone --depth=1 $LINK_GCC_ARM aarch32-gcc
 # toolchains
 git clone --depth=1 $LINK_TOOLCHAINS toolchains
}

cleaning_cache() {
  cd ~/kernel
  if [ -f ~/log_build.txt ]; then
    rm -rf ~/log_build.txt
  fi
  if [ -d out ]; then
    rm -rf out
  fi
  if [ -d HASIL ]; then
    rm -rf HASIL/**
  fi
  if [ -d ~/AnyKernel ]; then
    rm -rf ~/AnyKernel
  fi
}

sticker() {
  curl -s -X POST "https://api.telegram.org/bot$token/sendSticker" \
    -d sticker="CAACAgEAAxkBAAEnKnJfZOFzBnwC3cPwiirjZdgTMBMLRAACugEAAkVfBy-aN927wS5blhsE" \
    -d chat_id=$chat_id
}

sendinfo() {
  cd ~/kernel
  curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
    -d chat_id="$chat_id" \
    -d "disable_web_page_preview=true" \
    -d "parse_mode=html" \
    -d text="<b>$NAME_KERNEL</b>%0A| USING DEFCONFIG <b>$DEFCONFIG_NAME</b> |%0ABuild started on <code>CirrusCI</code>%0AFor device ${DEVICE_NAME} %0A | Build By <b>$KBUILD_BUILD_USER</b> %0A| Local Version: $LOCALVERSION | %0A branch <code>$(git rev-parse --abbrev-ref HEAD)</code> (master)%0AUnder commit <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0AUsing compiler: %0AStarted on <code>$(date)</code>%0A<b>Build Status:</b> Beta"
}

push() {
  cd ~/AnyKernel
  sha512_hash="$(sha512sum ${NAME_KERNEL}-*.zip | cut -f1 -d ' ')"
  ZIP1=$(echo ${NAME_KERNEL}-*.zip)
  mv ~/log_build.txt .
  ZIP2=log_build.txt
  minutes=$(($DIFF / 60))
  seconds=$(($DIFF % 60))
  curl -F document=@$ZIP1 "https://api.telegram.org/bot$token/sendDocument" \
    -F chat_id="$chat_id" \
    -F "disable_web_page_preview=true" \
    -F "parse_mode=html" \
    -F caption="Build took ${minutes} minute(s) and ${seconds} second(s). |\n USING DEFCONFIG <b>$DEFCONFIG_NAME</b> |\n For ${DEVICE_NAME} |\n Build By <b>$KBUILD_BUILD_USER</b> |\n Local Version: $LOCALVERSION |\n <b>$(${GCC}gcc --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')</b> |\n <b>SHA512SUM</b>: <code>$sha512_hash</code>"
  curl -F document=@$ZIP2 "https://api.telegram.org/bot$token/sendDocument" \
    -F chat_id="$chat_id" \
    -F "disable_web_page_preview=true" \
    -F "parse_mode=html" \
    -F caption="LOGGER BUILD FILE\n took ${minutes} minute(s) and ${seconds} second(s). |\n USING DEFCONFIG <b>$DEFCONFIG_NAME</b> |\n For ${DEVICE_NAME} |\n Build By <b>$KBUILD_BUILD_USER</b> |\n Local Version: $LOCALVERSION "
}



error_handler() {
  cd ~/AnyKernel
  mv ~/log_build.txt .
  ZIP=log_build.txt
  minutes=$(($DIFF / 60))
  seconds=$(($DIFF % 60))
  curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
    -F chat_id="$chat_id" \
    -F "disable_web_page_preview=true" \
    -F "parse_mode=html" \
    -F caption="Build encountered an error.\n took ${minutes} minute(s) and ${seconds} second(s). \n USING DEFCONFIG <b>$DEFCONFIG_NAME</b> |\n For ${DEVICE_NAME} |%\n Build By <b>$KBUILD_BUILD_USER</b> |%\n Local Version: $LOCALVERSION"
  exit 1
}

compile() {
  cd ~/kernel
  #ubah nama kernel dan dev builder
  printf "\nFinal Repository kernel Should Look Like...\n" && ls -lAog ~/kernel
  export ARCH=arm64

  #mulai mengcompile kernel
  [ -d "out" ] && rm -rf out
  mkdir -p out

  make O=out ARCH=arm64 $DEFCONFIG_NAME

 if [ -z "$ANDROID_TOOLCHAINS" ]
then
	# physwizz toolchain path
	ANDROID_TOOLCHAINS=""
fi

export PLATFORM_VERSION=13
export ANDROID_MAJOR_VERSION=t
export ARCH=arm64
export KCFLAGS="-mtune=cortex-a55"
export KCPPFLAGS="$KCFLAGS"

export KBUILD_BUILD_USER=linux
export KBUILD_BUILD_HOST=SM_M127F
export KBUILD_BUILD_TIMESTAMP="$(date -Ru${SOURCE_DATE_EPOCH:+d @$SOURCE_DATE_EPOCH})"

# GCC toolchain
export CROSS_COMPILE="{PWD}/aarch64-linux-android-4.9/bin/aarch64-linux-android-"
# CLANG toolchain
export CLANG_PATH="{PWD}/android_prebuilts_clang_host_linux-x86_clang-5484270-9.0/bin/"
# CLANG_TRIPLE toolchain
export CLANG_TRIPLE="{PWD}/proton-clang-13-clang/bin/aarch64-linux-gnu-"

unset ANDROID_TOOLCHAINS


DEFCONFIG="$DEFCONFIG_NAME"

echo
echo "Configuring with defconfig: $DEFCONFIG_NAME"
makecmd "$DEFCONFIG_NAME"
echo
echo Building the kernel:
echo ====================
makecmd -j"$(nproc)"
  

  cp out/arch/arm64/boot/Image.gz-dtb ~/AnyKernel
}

zipping() {
  cd ~/AnyKernel
  zip -r9 ${NAME_KERNEL}-${VENDOR_NAME}-${TANGGAL}.zip *
  cd ..
}

trap error_handler ERR
{
initial_kernel 2>&1 | tee ~/log_build.txt
cleaning_cache 2>&1 | tee -a ~/log_build.txt
clone_git 2>&1 | tee -a ~/log_build.txt
sendinfo 2>&1 | tee -a ~/log_build.txt
compile 2>&1 | tee -a ~/log_build.txt
zipping 2>&1 | tee -a ~/log_build.txt
END=$(date +"%s")
DIFF=$(($END - $START))
} 
push
