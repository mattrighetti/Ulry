import styles from './ButtonSection.module.css';

export default function ButtonSection() {
    return (
        <>
            <a href='https://testflight.apple.com/join/QJVKOkdK'>
                <div className={styles.button}>
                    <h1>Join TestFlight</h1>
                </div>
            </a>
        </>
    )
}